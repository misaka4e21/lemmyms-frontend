module Feature.Editor.Update exposing (Msg(..), Outcome, UploadKind(..), load, loadComment, update)

import Api
import App.Feedback exposing (Flash(..))
import Feature.Authoring.State as AuthoringState
import Feature.Authoring.Update as Authoring
import Feature.Editor.State exposing (..)
import File exposing (File)
import Html exposing (label)
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Lemmy.Route as Route
import List
import Ports exposing (focus)
import Remote exposing (Remote(..))
import Ui.Rich
import Url exposing (Url)


type Msg
    = StartReply String
    | EditorTitleChanged String
    | AuthoringMsg Authoring.Msg
    | EditorFormatChanged String
    | EditorRemoveAttachment String
    | EditorFileSelected (Maybe File)
    | EditorSubmit
    | EditorUseLatest
    | EditorKeepDraft
    | Saved EditorMode Api.Response
    | Reloaded Api.Response
    | Uploaded EditorMode UploadKind Api.Response
    | SourceLoaded String Api.Response
    | CommentSourceLoaded String Api.Response


type UploadKind
    = ImageUploadKind
    | DocumentUploadKind


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem, navigation : Maybe String }


type alias Working =
    { editor : Maybe EditorState
    , source : Remote Source
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf
                message
                { editor = state.editor
                , source = state.source
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                }
    in
    ( { editor = next.editor, source = next.source }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem, navigation = next.navigation }
    )


authProblem : Working -> Api.Problem -> Working
authProblem model problem =
    if problem.status == 401 then
        { model | sessionProblem = Just problem }

    else
        model


urlEncode : String -> String
urlEncode =
    Url.percentEncode


postSource : Decode.Decoder Source
postSource =
    Decode.field "post_view" Domain.postView
        |> Decode.map
            (\view ->
                { title = view.post.name
                , body = Maybe.withDefault "" view.post.body
                , version = Maybe.withDefault "0" view.post.updatedAt
                }
            )


decodeUploaded : UploadKind -> Api.Response -> Result Api.Problem ( EditorAttachment, String )
decodeUploaded kind response =
    case kind of
        ImageUploadKind ->
            Api.decodeResponse Domain.imageUpload response
                |> Result.andThen
                    (\image ->
                        if String.isEmpty (String.trim image.filename) || not (Ui.Rich.safeUrl image.imageUrl) then
                            Err invalidUploadResponse

                        else
                            Ok
                                ( { id = image.filename
                                  , name = image.filename
                                  , reference = image.imageUrl
                                  , kind = ImageAttachment
                                  , contentType = Nothing
                                  , sizeBytes = Nothing
                                  }
                                , "![" ++ escapeMarkdownLabel image.filename ++ "](" ++ image.imageUrl ++ ")"
                                )
                    )

        DocumentUploadKind ->
            Api.decodeResponse Domain.fileUpload response
                |> Result.andThen
                    (\file ->
                        let
                            markdown =
                                "[" ++ escapeMarkdownLabel file.filename ++ "](" ++ file.url ++ ")"

                            isFileLink =
                                Markdown.extractFileAttachments markdown
                                    |> List.any (\attachment -> attachment.id == file.publicId)
                        in
                        if
                            String.isEmpty (String.trim file.publicId)
                                || String.isEmpty (String.trim file.filename)
                                || not (Ui.Rich.safeUrl file.url)
                                || not isFileLink
                        then
                            Err invalidUploadResponse

                        else
                            Ok
                                ( { id = file.publicId
                                  , name = file.filename
                                  , reference = file.url
                                  , kind = DocumentAttachment
                                  , contentType = Just file.contentType
                                  , sizeBytes = Just file.sizeBytes
                                  }
                                , markdown
                                )
                    )


invalidUploadResponse : Api.Problem
invalidUploadResponse =
    { status = 400, detail = "bad_request" }


appendMarkdown : String -> String -> String
appendMarkdown source link =
    let
        separator =
            if String.isEmpty (String.trim source) then
                ""

            else
                "\n\n"
    in
    String.trimRight source ++ separator ++ link ++ "\n"


escapeMarkdownLabel : String -> String
escapeMarkdownLabel value =
    value
        |> String.replace "\\" "\\\\"
        |> String.replace "[" "\\["
        |> String.replace "]" "\\]"


commentSource : Decode.Decoder Source
commentSource =
    Decode.field "comment_view" Domain.commentView
        |> Decode.map
            (\view ->
                { title = ""
                , body = view.comment.content
                , version = Maybe.withDefault "0" view.comment.updatedAt
                }
            )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        StartReply postId ->
            ( { model | editor = Just (emptyEditor (CreateReply postId)) }, focus "editor-body" )

        EditorTitleChanged value ->
            setEditor model (\editor -> { editor | title = value, problem = Nothing }) Cmd.none

        AuthoringMsg authoringMessage ->
            case model.editor of
                Just editor ->
                    let
                        ( authoring, command, outcome ) =
                            Authoring.update authoringMessage editor.authoring
                    in
                    ( { model
                        | editor =
                            Just
                                { editor
                                    | authoring = authoring
                                    , attachments = syncAttachments editor.attachments (AuthoringState.value authoring)
                                    , problem =
                                        if outcome.changed then
                                            Nothing

                                        else
                                            editor.problem
                                }
                      }
                    , Cmd.map AuthoringMsg command
                    )

                Nothing ->
                    ( model, Cmd.none )

        EditorFormatChanged value ->
            setEditor model (\editor -> { editor | format = value, problem = Nothing }) Cmd.none

        EditorRemoveAttachment id ->
            setEditor model
                (\editor -> { editor | attachments = List.filter (\item -> item.id /= id) editor.attachments, problem = Nothing })
                Cmd.none

        EditorFileSelected maybeFile ->
            case ( maybeFile, model.editor ) of
                ( Just file, Just editor ) ->
                    let
                        kind =
                            if String.startsWith "image/" (String.toLower (File.mime file)) then
                                ImageUploadKind

                            else
                                DocumentUploadKind

                        command =
                            case kind of
                                ImageUploadKind ->
                                    Api.upload csrf "post" file (Uploaded editor.mode kind)

                                DocumentUploadKind ->
                                    Api.uploadFile file (Uploaded editor.mode kind)
                    in
                    ( { model | editor = Just { editor | uploading = True, problem = Nothing } }, command )

                _ ->
                    ( model, Cmd.none )

        EditorSubmit ->
            case model.editor of
                Just editor ->
                    if editor.saving then
                        ( model, Cmd.none )

                    else
                        submitEditor csrf model editor

                Nothing ->
                    ( model, Cmd.none )

        EditorUseLatest ->
            case ( model.editor, model.editor |> Maybe.andThen .conflict ) of
                ( Just editor, Just source ) ->
                    ( { model
                        | editor =
                            Just
                                { editor
                                    | title = source.title
                                    , authoring = AuthoringState.setValue source.body editor.authoring
                                    , format = "markdown"
                                    , version = Just source.version
                                    , attachments = sourceAttachments source
                                    , conflict = Nothing
                                    , problem = Nothing
                                }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        EditorKeepDraft ->
            setEditor model (\editor -> { editor | conflict = Nothing }) Cmd.none

        Saved mode response ->
            let
                decoder =
                    case mode of
                        CreateReply _ ->
                            Decode.map (\comment -> comment.post.id) (Decode.field "comment_view" Domain.commentView)

                        EditComment _ ->
                            Decode.map (\comment -> comment.post.id) (Decode.field "comment_view" Domain.commentView)

                        _ ->
                            Decode.map (\post -> post.post.id) (Decode.field "post_view" Domain.postView)
            in
            case Api.decodeResponse decoder response of
                Ok postId ->
                    ( { model
                        | editor = Nothing
                        , navigation = Just (Route.path (Route.Post postId Nothing))
                      }
                    , Cmd.none
                    )

                Err problem ->
                    case model.editor of
                        Just editor ->
                            if problem.status == 409 && String.contains "edit_conflict" problem.detail then
                                ( { model | editor = Just { editor | saving = False, problem = Just problem }, source = Loading }
                                , case mode of
                                    EditPost postId ->
                                        Api.get ("/post?id=" ++ urlEncode postId) Reloaded

                                    _ ->
                                        Cmd.none
                                )

                            else
                                let
                                    base =
                                        authProblem model problem
                                in
                                ( { base | editor = Just { editor | saving = False, problem = Just problem } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

        Reloaded response ->
            case Api.decodeResponse postSource response of
                Ok source ->
                    case model.editor of
                        Just editor ->
                            ( { model | editor = Just { editor | conflict = Just source }, source = Ready source }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Err problem ->
                    ( { model | flash = FlashProblem problem }, Cmd.none )

        Uploaded mode kind response ->
            case model.editor of
                Just editor ->
                    if editor.mode /= mode then
                        ( model, Cmd.none )

                    else
                        case decodeUploaded kind response of
                            Ok ( attachment, markdown ) ->
                                let
                                    nextBody =
                                        appendMarkdown (body editor) markdown

                                    nextAttachments =
                                        syncAttachments (editor.attachments ++ [ attachment ]) nextBody
                                in
                                ( { model
                                    | editor =
                                        Just
                                            { editor
                                                | uploading = False
                                                , authoring = AuthoringState.setValue nextBody editor.authoring
                                                , attachments = nextAttachments
                                                , problem = Nothing
                                            }
                                    , flash = FlashUploaded
                                  }
                                , focus "editor-body"
                                )

                            Err problem ->
                                ( { model
                                    | flash = FlashUploadFailed
                                    , editor = Just { editor | uploading = False, problem = Just problem }
                                  }
                                , Cmd.none
                                )

                Nothing ->
                    ( model, Cmd.none )

        SourceLoaded id response ->
            case Api.decodeResponse postSource response of
                Ok source ->
                    ( { model
                        | source = Ready source
                        , editor =
                            Just
                                { mode = EditPost id
                                , title = source.title
                                , authoring = AuthoringState.init "editor-body" source.body
                                , format = "markdown"
                                , version = Just source.version
                                , attachments = sourceAttachments source
                                , uploading = False
                                , saving = False
                                , problem = Nothing
                                , conflict = Nothing
                                }
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( authProblem { model | source = Failed problem } problem, Cmd.none )

        CommentSourceLoaded id response ->
            case Api.decodeResponse commentSource response of
                Ok source ->
                    ( { model
                        | source = Ready source
                        , editor =
                            Just
                                { mode = EditComment id
                                , title = ""
                                , authoring = AuthoringState.init "editor-body" source.body
                                , format = "markdown"
                                , version = Just source.version
                                , attachments = sourceAttachments source
                                , uploading = False
                                , saving = False
                                , problem = Nothing
                                , conflict = Nothing
                                }
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( authProblem { model | source = Failed problem } problem, Cmd.none )


submitEditor : String -> Working -> EditorState -> ( Working, Cmd Msg )
submitEditor csrf model editor =
    let
        editorBody =
            body editor

        ( method, url, encodedBody ) =
            case editor.mode of
                CreateTopic targetCommunity ->
                    ( "POST"
                    , "/post"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "name", Encode.string editor.title )
                            , ( "community_id", Encode.int (String.toInt targetCommunity |> Maybe.withDefault 0) )
                            , ( "body", Encode.string editorBody )
                            ]
                        )
                    )

                CreateReply postId ->
                    ( "POST"
                    , "/comment"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "content", Encode.string editorBody )
                            , ( "post_id", Encode.int (String.toInt postId |> Maybe.withDefault 0) )
                            ]
                        )
                    )

                EditPost postId ->
                    ( "PUT"
                    , "/post"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "post_id", Encode.int (String.toInt postId |> Maybe.withDefault 0) )
                            , ( "name", Encode.string editor.title )
                            , ( "body", Encode.string editorBody )
                            ]
                        )
                    )

                EditComment commentId ->
                    ( "PUT"
                    , "/comment"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "comment_id", Encode.int (String.toInt commentId |> Maybe.withDefault 0) )
                            , ( "content", Encode.string editorBody )
                            ]
                        )
                    )
    in
    ( { model | editor = Just { editor | saving = True, problem = Nothing } }
    , Api.send csrf method url encodedBody (Saved editor.mode)
    )


setEditor : Working -> (EditorState -> EditorState) -> Cmd Msg -> ( Working, Cmd Msg )
setEditor model transform command =
    ( { model | editor = Maybe.map transform model.editor }, command )


load : String -> Model -> ( Model, Cmd Msg )
load id model =
    ( { model | source = Loading }
    , Api.get ("/post?id=" ++ urlEncode id) (SourceLoaded id)
    )


loadComment : String -> Model -> ( Model, Cmd Msg )
loadComment id model =
    ( { model | source = Loading }
    , Api.get ("/comment?id=" ++ urlEncode id) (CommentSourceLoaded id)
    )
