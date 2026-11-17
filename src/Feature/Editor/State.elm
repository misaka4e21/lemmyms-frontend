module Feature.Editor.State exposing (..)

import Api
import Feature.Authoring.State as Authoring
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Remote exposing (Remote(..))


type EditorMode
    = CreateTopic String
    | CreateReply String
    | EditPost String
    | EditComment String


type alias Source =
    { title : String
    , body : String
    , version : String
    }


type AttachmentKind
    = ImageAttachment
    | DocumentAttachment


type alias EditorAttachment =
    { id : String
    , name : String
    , reference : String
    , kind : AttachmentKind
    , contentType : Maybe String
    , sizeBytes : Maybe Int
    }


type alias EditorState =
    { mode : EditorMode
    , title : String
    , authoring : Authoring.Model
    , format : String
    , version : Maybe String
    , attachments : List EditorAttachment
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    , conflict : Maybe Source
    }


emptyEditor : EditorMode -> EditorState
emptyEditor mode =
    { mode = mode
    , title = ""
    , authoring = Authoring.init "editor-body" ""
    , format = "markdown"
    , version = Nothing
    , attachments = []
    , uploading = False
    , saving = False
    , problem = Nothing
    , conflict = Nothing
    }


body : EditorState -> String
body editor =
    Authoring.value editor.authoring


sourceAttachments : Source -> List EditorAttachment
sourceAttachments source =
    Markdown.extractFileAttachments source.body
        |> List.map
            (\attachment ->
                { id = attachment.id
                , name = attachment.name
                , reference = attachment.url
                , kind = DocumentAttachment
                , contentType = Nothing
                , sizeBytes = Nothing
                }
            )


syncAttachments : List EditorAttachment -> String -> List EditorAttachment
syncAttachments existing source =
    let
        images =
            List.filter (\attachment -> attachment.kind == ImageAttachment) existing

        documents =
            Markdown.extractFileAttachments source
                |> List.map
                    (\attachment ->
                        case List.filter (\current -> current.kind == DocumentAttachment && current.id == attachment.id) existing of
                            current :: _ ->
                                { current | name = attachment.name, reference = attachment.url }

                            [] ->
                                { id = attachment.id
                                , name = attachment.name
                                , reference = attachment.url
                                , kind = DocumentAttachment
                                , contentType = Nothing
                                , sizeBytes = Nothing
                                }
                    )
    in
    images ++ documents


type alias Model =
    { editor : Maybe EditorState, source : Remote Source }


initial : Model
initial =
    { editor = Nothing, source = NotAsked }
