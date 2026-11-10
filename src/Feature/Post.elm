module Feature.Post exposing (Config, Model, Msg(..), Outcome, initial, isBusy, likeKey, load, pagePost, reset, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import Generated.I18n as Translations
import Html exposing (Html, button, div, h2, label, option, p, section, select, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.CommentTree as CommentTree
import Lemmy.Domain as Domain
import List
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (entityHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { post : Remote Domain.PostView
    , replies : Remote (Domain.Page (CommentTree.Threaded Domain.CommentView))
    , expandedReplies : Set String
    , busy : Set String
    }


initial : Model
initial =
    { post = NotAsked, replies = NotAsked, expandedReplies = Set.empty, busy = Set.empty }


likeKey : String -> String
likeKey id =
    "like-" ++ id


isBusy : String -> Set String -> Bool
isBusy id busy =
    List.any (\key -> Set.member key busy)
        [ likeKey id
        , "vote-" ++ id ++ "-1"
        , "vote-" ++ id ++ "-0"
        , "vote-" ++ id ++ "--1"
        , "save-" ++ id
        , "read-" ++ id
        , "hide-" ++ id
        ]


type Mutation
    = LikeMutation String Bool
    | VoteMutation String Int
    | SaveMutation String Bool
    | ReadMutation String
    | HideMutation String Bool


type Msg
    = ToggleReplies String
    | ToggleLike String Bool
    | Vote String Int
    | ToggleSave String Bool
    | MarkRead String
    | ToggleHideForMe String Bool
    | CommentVote String Int
    | CommentSave String Bool
    | CommentMutationDone Api.Response
    | DeleteComment String
    | CommentDeleted Api.Response
    | SortChanged String
    | DepthChanged Int
    | ConfirmDelete String
    | MutationDone Mutation Api.Response
    | Refreshed Mutation Api.Response
    | Deleted Api.Response
    | PostLoaded Api.Response
    | RepliesLoaded Api.Response


type alias Outcome =
    { flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshed : Maybe Domain.PostView
    , reloadRoute : Bool
    }


type alias Working =
    { post : Remote Domain.PostView
    , replies : Remote (Domain.Page (CommentTree.Threaded Domain.CommentView))
    , expandedReplies : Set String
    , busy : Set String
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshed : Maybe Domain.PostView
    , reloadRoute : Bool
    }


update : String -> Url -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf url message state =
    let
        ( next, command ) =
            updateWorking csrf
                url
                message
                { post = state.post
                , replies = state.replies
                , expandedReplies = state.expandedReplies
                , busy = state.busy
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                , refreshed = Nothing
                , reloadRoute = False
                }
    in
    ( { post = next.post
      , replies = next.replies
      , expandedReplies = next.expandedReplies
      , busy = next.busy
      }
    , command
    , { flash = next.flash
      , sessionProblem = next.sessionProblem
      , navigation = next.navigation
      , refreshed = next.refreshed
      , reloadRoute = next.reloadRoute
      }
    )


updateWorking : String -> Url -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf url message model =
    case message of
        ToggleReplies id ->
            ( { model
                | expandedReplies =
                    if Set.member id model.expandedReplies then
                        Set.remove id model.expandedReplies

                    else
                        Set.insert id model.expandedReplies
              }
            , Cmd.none
            )

        ToggleLike id liked ->
            postMutation csrf model (LikeMutation id liked)

        Vote id score ->
            postMutation csrf model (VoteMutation id score)

        ToggleSave id saved ->
            postMutation csrf model (SaveMutation id saved)

        MarkRead id ->
            postMutation csrf model (ReadMutation id)

        ToggleHideForMe id hidden ->
            postMutation csrf model (HideMutation id hidden)

        CommentVote id score ->
            ( model
            , Api.send csrf
                "POST"
                "/comment/like"
                (Encode.encode 0 (Encode.object [ ( "comment_id", Encode.int (idValue id) ), ( "is_upvote", scoreValue score ) ]))
                CommentMutationDone
            )

        CommentSave id saved ->
            ( model
            , Api.send csrf
                "PUT"
                "/comment/save"
                (Encode.encode 0 (Encode.object [ ( "comment_id", Encode.int (idValue id) ), ( "save", Encode.bool (not saved) ) ]))
                CommentMutationDone
            )

        CommentMutationDone response ->
            case Api.decodeUnit response of
                Ok () ->
                    case Route.parse url of
                        Route.Post id ->
                            let
                                sort =
                                    Route.query "sort" url
                                        |> (\value ->
                                                if List.member value [ "new", "old", "top", "controversial" ] then
                                                    value

                                                else
                                                    "old"
                                           )

                                maxDepth =
                                    Route.query "max_depth" url
                                        |> String.toInt
                                        |> Maybe.withDefault 6
                                        |> clamp 1 8
                            in
                            ( { model | replies = Loading }
                            , Api.get
                                ("/comment/list?post_id="
                                    ++ urlEncode id
                                    ++ "&limit=20&sort="
                                    ++ sort
                                    ++ "&max_depth="
                                    ++ String.fromInt maxDepth
                                )
                                RepliesLoaded
                            )

                        _ ->
                            ( model, Cmd.none )

                Err problem ->
                    ( problemState model problem, Cmd.none )

        DeleteComment id ->
            ( model
            , Api.send csrf
                "DELETE"
                "/comment"
                (Encode.encode 0 (Encode.object [ ( "comment_id", Encode.int (idValue id) ), ( "deleted", Encode.bool True ) ]))
                CommentDeleted
            )

        CommentDeleted response ->
            case Api.decodeUnit response of
                Ok () ->
                    reloadReplies url model

                Err problem ->
                    ( problemState model problem, Cmd.none )

        SortChanged sort ->
            let
                depth =
                    Route.query "max_depth" url |> String.toInt |> Maybe.withDefault 6 |> clamp 1 8
            in
            ( { model | navigation = Just (Route.replyPageUrl url sort depth (Route.offset url)) }, Cmd.none )

        DepthChanged depth ->
            let
                sort =
                    Route.query "sort" url
                        |> (\value ->
                                if List.member value [ "new", "old", "top", "controversial" ] then
                                    value

                                else
                                    "old"
                           )
            in
            ( { model | navigation = Just (Route.replyPageUrl url sort (clamp 1 8 depth) (Route.offset url)) }, Cmd.none )

        ConfirmDelete id ->
            ( { model | busy = Set.insert ("delete-" ++ id) model.busy }
            , Api.send csrf "DELETE" "/post" (Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (idValue id) ), ( "deleted", Encode.bool True ) ])) Deleted
            )

        MutationDone mutation response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        id =
                            mutationPostId mutation

                        cleaned =
                            { model
                                | busy = Set.remove (mutationKey mutation) model.busy
                                , flash = FlashSaved
                                , reloadRoute =
                                    case mutation of
                                        HideMutation _ _ ->
                                            True

                                        _ ->
                                            False
                            }
                    in
                    ( cleaned
                    , Api.get ("/post?id=" ++ urlEncode id) (Refreshed mutation)
                    )

                Err problem ->
                    ( problemState { model | busy = Set.remove (mutationKey mutation) model.busy } problem, Cmd.none )

        Refreshed _ response ->
            case Api.decodeResponse Domain.postView response of
                Ok post ->
                    ( { model
                        | post =
                            case model.post of
                                Ready current ->
                                    if current.post.id == post.post.id then
                                        Ready post

                                    else
                                        model.post

                                _ ->
                                    model.post
                        , refreshed = Just post
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( problemState model problem, Cmd.none )

        Deleted response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | flash = FlashDeleted, navigation = Just "/" }, Cmd.none )

                Err problem ->
                    ( problemState model problem, Cmd.none )

        PostLoaded response ->
            case Api.decodeResponse Domain.postView response of
                Ok post ->
                    ( { model | post = Ready post }, Cmd.none )

                Err problem ->
                    ( problemState { model | post = Failed problem } problem, Cmd.none )

        RepliesLoaded response ->
            case Api.decodeResponse Domain.threadedPage response of
                Ok page ->
                    ( { model | replies = Ready page }, Cmd.none )

                Err problem ->
                    ( problemState { model | replies = Failed problem } problem, Cmd.none )


postMutation : String -> Working -> Mutation -> ( Working, Cmd Msg )
postMutation csrf model mutation =
    let
        id =
            mutationPostId mutation

        key =
            mutationKey mutation
    in
    if Set.member key model.busy then
        ( model, Cmd.none )

    else
        let
            ( method, url, body ) =
                case mutation of
                    LikeMutation _ liked ->
                        ( "POST"
                        , "/post/like"
                        , Encode.encode 0
                            (Encode.object
                                [ ( "post_id", Encode.int (idValue id) )
                                , ( "is_upvote"
                                  , if liked then
                                        Encode.null

                                    else
                                        Encode.bool True
                                  )
                                ]
                            )
                        )

                    VoteMutation _ score ->
                        ( "POST"
                        , "/post/like"
                        , Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (idValue id) ), ( "is_upvote", scoreValue score ) ])
                        )

                    SaveMutation _ saved ->
                        ( "PUT"
                        , "/post/save"
                        , Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (idValue id) ), ( "save", Encode.bool (not saved) ) ])
                        )

                    ReadMutation _ ->
                        ( "POST", "/post/mark_as_read", Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (idValue id) ), ( "read", Encode.bool True ) ]) )

                    HideMutation _ hidden ->
                        ( "POST"
                        , "/post/hide"
                        , Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (idValue id) ), ( "hide", Encode.bool (not hidden) ) ])
                        )
        in
        ( { model | busy = Set.insert key model.busy, flash = NoFlash }
        , Api.send csrf method url body (MutationDone mutation)
        )


mutationKey : Mutation -> String
mutationKey mutation =
    case mutation of
        LikeMutation id _ ->
            "like-" ++ id

        VoteMutation id score ->
            "vote-" ++ id ++ "-" ++ String.fromInt score

        SaveMutation id _ ->
            "save-" ++ id

        ReadMutation id ->
            "read-" ++ id

        HideMutation id _ ->
            "hide-" ++ id


mutationPostId : Mutation -> String
mutationPostId mutation =
    case mutation of
        LikeMutation id _ ->
            id

        VoteMutation id _ ->
            id

        SaveMutation id _ ->
            id

        ReadMutation id ->
            id

        HideMutation id _ ->
            id


problemState : Working -> Api.Problem -> Working
problemState model problem =
    { model
        | flash = FlashProblem problem
        , sessionProblem =
            if problem.status == 401 then
                Just problem

            else
                Nothing
    }


urlEncode : String -> String
urlEncode =
    Url.percentEncode


type alias Config msg =
    { retry : msg
    , postCard : Domain.PostView -> Html msg
    , threadedPostCard : Domain.CommentView -> Html msg -> Html msg
    , startReply : String -> msg
    , editor : Html msg
    , sort : String
    , maxDepth : Int
    , sortChanged : String -> msg
    , depthChanged : Int -> msg
    , isExpanded : String -> Bool
    , onReplies : String -> msg
    }


type alias ViewModel =
    { post : Remote Domain.PostView
    , replies : Remote (Domain.Page (CommentTree.Threaded Domain.CommentView))
    , url : Url
    }


pagePost : Config msg -> ViewModel -> Active -> String -> Html msg
pagePost config model active postId =
    entityHeading
        (case model.post of
            Ready post ->
                if String.isEmpty post.post.name then
                    Translations.repliesTitle active.texts

                else
                    post.post.name

            _ ->
                Translations.repliesTitle active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote config.retry
                active.texts
                model.post
                (\post ->
                    div [ A.class "stack" ]
                        [ config.postCard post
                        , if not post.post.locked && not post.post.deleted then
                            button [ A.class "filled-button", Events.onClick (config.startReply postId) ]
                                [ text (Translations.reply active.texts) ]

                          else
                            text ""
                        , config.editor
                        ]
                )
            , h2 [] [ text (Translations.repliesTitle active.texts) ]
            , replyControls config active
            , viewRemote config.retry
                active.texts
                model.replies
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (viewThreaded config active model) page.items)
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]
                )
            ]
        )


replyControls : Config msg -> Active -> Html msg
replyControls config active =
    div [ A.class "card actions wrap" ]
        [ div []
            [ label [ A.for "reply-sort" ] [ text (Translations.replySort active.texts) ]
            , select
                [ A.id "reply-sort"
                , Events.on "change" (Decode.map config.sortChanged (Decode.at [ "target", "value" ] Decode.string))
                ]
                [ option [ A.value "old", A.selected (config.sort == "old") ] [ text (Translations.sortOld active.texts) ]
                , option [ A.value "new", A.selected (config.sort == "new") ] [ text (Translations.sortNew active.texts) ]
                , option [ A.value "top", A.selected (config.sort == "top") ] [ text (Translations.sortTop active.texts) ]
                , option [ A.value "controversial", A.selected (config.sort == "controversial") ] [ text (Translations.sortControversial active.texts) ]
                ]
            ]
        , div []
            [ label [ A.for "reply-depth" ] [ text (Translations.maxDepth active.texts) ]
            , select
                [ A.id "reply-depth"
                , Events.on "change" (Decode.map config.depthChanged (Decode.at [ "target", "value" ] Decode.string |> Decode.map (String.toInt >> Maybe.withDefault 6)))
                ]
                (List.map
                    (\depth ->
                        option [ A.value (String.fromInt depth), A.selected (config.maxDepth == depth) ]
                            [ text (String.fromInt depth) ]
                    )
                    (List.range 1 8)
                )
            ]
        ]


viewThreaded : Config msg -> Active -> ViewModel -> CommentTree.Threaded Domain.CommentView -> Html msg
viewThreaded config active model (CommentTree.Threaded node) =
    let
        comment =
            node.value

        commentId =
            String.fromInt comment.comment.id

        children =
            if config.isExpanded commentId && not (List.isEmpty node.children) then
                div [ A.class "nested stack" ] (List.map (viewThreaded config active model) node.children)

            else
                text ""
    in
    config.threadedPostCard comment children


reset : Model -> Model
reset model =
    { model | post = NotAsked, replies = NotAsked, expandedReplies = Set.empty, busy = Set.empty }


idValue : String -> Int
idValue id =
    String.toInt id |> Maybe.withDefault 0


scoreValue : Int -> Encode.Value
scoreValue score =
    if score > 0 then
        Encode.bool True

    else if score < 0 then
        Encode.bool False

    else
        Encode.null


cursorQuery : Url -> String
cursorQuery url =
    case Route.cursor url of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


reloadReplies : Url -> Working -> ( Working, Cmd Msg )
reloadReplies url model =
    let
        sort =
            Route.query "sort" url
                |> (\value ->
                        if List.member value [ "new", "old", "top", "controversial" ] then
                            value

                        else
                            "old"
                   )

        maxDepth =
            Route.query "max_depth" url
                |> String.toInt
                |> Maybe.withDefault 6
                |> clamp 1 8
    in
    ( { model | replies = Loading }
    , case Route.parse url of
        Route.Post postId ->
            Api.get
                ("/comment/list?post_id="
                    ++ urlEncode postId
                    ++ "&limit=20&sort="
                    ++ sort
                    ++ "&max_depth="
                    ++ String.fromInt maxDepth
                )
                RepliesLoaded

        _ ->
            Cmd.none
    )


load : String -> Url -> Model -> ( Model, Cmd Msg )
load id url model =
    let
        sort =
            Route.query "sort" url
                |> (\value ->
                        if List.member value [ "new", "old", "top", "controversial" ] then
                            value

                        else
                            "old"
                   )

        maxDepth =
            Route.query "max_depth" url
                |> String.toInt
                |> Maybe.withDefault 6
                |> clamp 1 8
    in
    ( { model | post = Loading, replies = Loading, expandedReplies = Set.empty }
    , Cmd.batch
        [ Api.get ("/post?id=" ++ urlEncode id) PostLoaded
        , Api.get
            ("/comment/list?post_id="
                ++ urlEncode id
                ++ "&limit=20&sort="
                ++ sort
                ++ "&max_depth="
                ++ String.fromInt maxDepth
                ++ cursorQuery url
            )
            RepliesLoaded
        ]
    )
