module Feature.Post exposing (CommentModAction(..), Config, Model, Msg(..), Outcome, PostModAction(..), VoteTarget(..), initial, isBusy, likeKey, load, pagePost, reset, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import Generated.I18n as Translations
import Html exposing (Html, bdi, button, div, h2, label, li, option, p, section, select, text, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.CommentTree as CommentTree
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Ports exposing (closeDialog, focus, openDialog)
import Remote exposing (Remote(..))
import Set exposing (Set)
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (entityHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { post : Remote Domain.PostView
    , replies : Remote (Domain.Page (CommentTree.Threaded Domain.CommentView))
    , crossPosts : List Domain.PostView
    , expandedReplies : Set String
    , busy : Set String
    , focusComment : Maybe String
    , voteDialog : Maybe VoteDialog
    }


initial : Model
initial =
    { post = NotAsked
    , replies = NotAsked
    , crossPosts = []
    , expandedReplies = Set.empty
    , busy = Set.empty
    , focusComment = Nothing
    , voteDialog = Nothing
    }


type PostModAction
    = RemovePostAction Bool
    | LockPostAction Bool
    | FeaturePostAction Bool


type CommentModAction
    = RemoveCommentAction Bool
    | LockCommentAction Bool
    | DistinguishCommentAction Bool


type VoteTarget
    = PostVotes String
    | CommentVotes String


type alias VoteDialog =
    { target : VoteTarget
    , votes : Remote (Domain.Page Domain.VoteView)
    }


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
    | ModeratePost String PostModAction
    | ModerateComment String CommentModAction
    | ModerationDone Api.Response
    | BlockPerson Int Bool
    | BlockCommunity Int Bool
    | BlockDone Api.Response
    | SetRead String Bool
    | OpenVotes VoteTarget
    | CloseVotes
    | VotesLoaded Api.Response


type alias Outcome =
    { flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshed : Maybe Domain.PostView
    , reloadRoute : Bool
    , focusTarget : Maybe String
    }


type alias Working =
    { post : Remote Domain.PostView
    , replies : Remote (Domain.Page (CommentTree.Threaded Domain.CommentView))
    , crossPosts : List Domain.PostView
    , expandedReplies : Set String
    , busy : Set String
    , focusComment : Maybe String
    , voteDialog : Maybe VoteDialog
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshed : Maybe Domain.PostView
    , reloadRoute : Bool
    , focusTarget : Maybe String
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
                , crossPosts = state.crossPosts
                , expandedReplies = state.expandedReplies
                , busy = state.busy
                , focusComment = state.focusComment
                , voteDialog = state.voteDialog
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                , refreshed = Nothing
                , reloadRoute = False
                , focusTarget = Nothing
                }
    in
    ( { post = next.post
      , replies = next.replies
      , crossPosts = next.crossPosts
      , expandedReplies = next.expandedReplies
      , busy = next.busy
      , focusComment = state.focusComment
      , voteDialog = next.voteDialog
      }
    , command
    , { flash = next.flash
      , sessionProblem = next.sessionProblem
      , navigation = next.navigation
      , refreshed = next.refreshed
      , reloadRoute = next.reloadRoute
      , focusTarget = next.focusTarget
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
                        Route.Post id _ ->
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
                                    ++ urlEncode (String.fromInt id)
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
            case Route.parse url of
                Route.Post postId _ ->
                    ( { model | navigation = Just (Route.postCommentsUrl postId sort depth Nothing) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

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
            case Route.parse url of
                Route.Post postId _ ->
                    ( { model | navigation = Just (Route.postCommentsUrl postId sort (clamp 1 8 depth) Nothing) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

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
            case Api.decodeResponse (Decode.field "post_view" Domain.postView) response of
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
            case Api.decodeResponse postDetailDecoder response of
                Ok ( post, crossPosts ) ->
                    ( { model | post = Ready post, crossPosts = crossPosts }, Cmd.none )

                Err problem ->
                    ( problemState { model | post = Failed problem } problem, Cmd.none )

        RepliesLoaded response ->
            case Api.decodeResponse Domain.threadedPage response of
                Ok page ->
                    let
                        target =
                            case model.focusComment of
                                Just id ->
                                    if commentExists id page.items then
                                        Just ("comment-" ++ id)

                                    else
                                        Just "main-heading"

                                Nothing ->
                                    Nothing
                    in
                    ( { model | replies = Ready page, focusTarget = target }, Cmd.none )

                Err problem ->
                    let
                        updated =
                            { model
                                | replies = Failed problem
                                , focusTarget =
                                    if model.focusComment /= Nothing then
                                        Just "main-heading"

                                    else
                                        Nothing
                            }
                    in
                    ( problemState updated problem, Cmd.none )

        ModeratePost id action ->
            ( { model | busy = Set.insert ("moderate-" ++ id) model.busy }
            , Api.send "" "POST" (postModerationPath action) (postModerationBody id action) ModerationDone
            )

        ModerateComment id action ->
            ( { model | busy = Set.insert ("moderate-comment-" ++ id) model.busy }
            , Api.send "" "POST" (commentModerationPath action) (commentModerationBody id action) ModerationDone
            )

        ModerationDone response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | busy = Set.empty, reloadRoute = True, flash = FlashSaved }, Cmd.none )

                Err problem ->
                    ( problemState { model | busy = Set.empty } problem, Cmd.none )

        BlockPerson id block ->
            ( { model | busy = Set.insert "block-person" model.busy }
            , Api.send "" "POST" "/account/block/person" (Encode.encode 0 (Encode.object [ ( "person_id", Encode.int id ), ( "block", Encode.bool block ) ])) BlockDone
            )

        BlockCommunity id block ->
            ( { model | busy = Set.insert "block-community" model.busy }
            , Api.send "" "POST" "/account/block/community" (Encode.encode 0 (Encode.object [ ( "community_id", Encode.int id ), ( "block", Encode.bool block ) ])) BlockDone
            )

        BlockDone response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | busy = Set.empty, reloadRoute = True, flash = FlashSaved }, Cmd.none )

                Err problem ->
                    ( problemState { model | busy = Set.empty } problem, Cmd.none )

        SetRead id read ->
            ( { model | busy = Set.insert ("read-" ++ id) model.busy }
            , Api.send ""
                "POST"
                "/post/mark_as_read"
                (Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (idValue id) ), ( "read", Encode.bool read ) ]))
                ModerationDone
            )

        OpenVotes target ->
            ( { model | voteDialog = Just { target = target, votes = Loading } }
            , Cmd.batch [ openDialog "vote-dialog", Api.get (voteListPath target) VotesLoaded ]
            )

        CloseVotes ->
            ( { model | voteDialog = Nothing }
            , Cmd.batch
                [ closeDialog "vote-dialog"
                , case model.voteDialog of
                    Just dialog ->
                        focus (voteTriggerId dialog.target)

                    Nothing ->
                        Cmd.none
                ]
            )

        VotesLoaded response ->
            case model.voteDialog of
                Just dialog ->
                    case Api.decodeResponse (Domain.page Domain.voteView) response of
                        Ok page ->
                            ( { model | voteDialog = Just { dialog | votes = Ready page } }, Cmd.none )

                        Err problem ->
                            ( { model | voteDialog = Just { dialog | votes = Failed problem } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


commentExists : String -> List (CommentTree.Threaded Domain.CommentView) -> Bool
commentExists id threads =
    CommentTree.flatten threads
        |> List.any (\comment -> String.fromInt comment.comment.id == id)


postDetailDecoder : Decode.Decoder ( Domain.PostView, List Domain.PostView )
postDetailDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "post_view" Domain.postView)
        (Decode.oneOf
            [ Decode.field "cross_posts" (Decode.list Domain.postView)
            , Decode.succeed []
            ]
        )


postModerationPath : PostModAction -> String
postModerationPath action =
    case action of
        RemovePostAction _ ->
            "/post/remove"

        LockPostAction _ ->
            "/post/lock"

        FeaturePostAction _ ->
            "/post/feature"


postModerationBody : String -> PostModAction -> String
postModerationBody id action =
    case action of
        RemovePostAction removed ->
            Encode.encode 0
                (Encode.object
                    [ ( "post_id", Encode.int (idValue id) )
                    , ( "removed", Encode.bool removed )
                    , ( "reason", Encode.string "" )
                    ]
                )

        LockPostAction locked ->
            Encode.encode 0
                (Encode.object
                    [ ( "post_id", Encode.int (idValue id) )
                    , ( "locked", Encode.bool locked )
                    , ( "reason", Encode.string "" )
                    ]
                )

        FeaturePostAction featured ->
            Encode.encode 0
                (Encode.object
                    [ ( "post_id", Encode.int (idValue id) )
                    , ( "featured", Encode.bool featured )
                    , ( "feature_type", Encode.string "community" )
                    ]
                )


commentModerationPath : CommentModAction -> String
commentModerationPath action =
    case action of
        RemoveCommentAction _ ->
            "/comment/remove"

        LockCommentAction _ ->
            "/comment/lock"

        DistinguishCommentAction _ ->
            "/comment/distinguish"


commentModerationBody : String -> CommentModAction -> String
commentModerationBody id action =
    case action of
        RemoveCommentAction removed ->
            Encode.encode 0
                (Encode.object
                    [ ( "comment_id", Encode.int (idValue id) )
                    , ( "removed", Encode.bool removed )
                    , ( "reason", Encode.string "" )
                    ]
                )

        LockCommentAction locked ->
            Encode.encode 0
                (Encode.object
                    [ ( "comment_id", Encode.int (idValue id) )
                    , ( "locked", Encode.bool locked )
                    , ( "reason", Encode.string "" )
                    ]
                )

        DistinguishCommentAction distinguished ->
            Encode.encode 0
                (Encode.object
                    [ ( "comment_id", Encode.int (idValue id) )
                    , ( "distinguished", Encode.bool distinguished )
                    ]
                )


voteListPath : VoteTarget -> String
voteListPath target =
    case target of
        PostVotes id ->
            "/post/like/list?post_id=" ++ Url.percentEncode id ++ "&limit=50"

        CommentVotes id ->
            "/comment/like/list?comment_id=" ++ Url.percentEncode id ++ "&limit=50"


voteTriggerId : VoteTarget -> String
voteTriggerId target =
    case target of
        PostVotes id ->
            "view-votes-post-" ++ id

        CommentVotes id ->
            "view-votes-comment-" ++ id


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
    , onMarkRead : String -> Bool -> msg
    , onBlockAuthor : Int -> Bool -> msg
    , onBlockCommunity : Int -> Bool -> msg
    , onRemovePost : String -> Bool -> msg
    , onLockPost : String -> Bool -> msg
    , onFeaturePost : String -> Bool -> msg
    , onViewVotes : String -> msg
    , onCloseVotes : msg
    }


type alias ViewModel =
    { post : Remote Domain.PostView
    , replies : Remote (Domain.Page (CommentTree.Threaded Domain.CommentView))
    , crossPosts : List Domain.PostView
    , voteDialog : Maybe VoteDialog
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
                        , crossPostsSection config active model.crossPosts
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
            , voteDialogView config active model.voteDialog
            ]
        )


crossPostsSection : Config msg -> Active -> List Domain.PostView -> Html msg
crossPostsSection config active posts =
    if List.isEmpty posts then
        text ""

    else
        section [ A.class "stack" ]
            [ h2 [] [ text (Translations.crossPosts active.texts) ]
            , div [ A.class "stack" ] (List.map config.postCard posts)
            ]


voteDialogView : Config msg -> Active -> Maybe VoteDialog -> Html msg
voteDialogView config active dialog =
    case dialog of
        Nothing ->
            text ""

        Just value ->
            Html.node "dialog"
                [ A.id "vote-dialog"
                , A.class "confirmation"
                , A.attribute "aria-labelledby" "vote-dialog-title"
                , Events.on "close" (Decode.succeed config.onCloseVotes)
                ]
                [ div [ A.class "form-stack" ]
                    [ h2 [ A.id "vote-dialog-title" ] [ text (Translations.viewVotes active.texts) ]
                    , viewRemote config.retry
                        active.texts
                        value.votes
                        (\page ->
                            if List.isEmpty page.items then
                                p [ A.class "muted" ] [ text (Translations.noVotes active.texts) ]

                            else
                                ul [ A.class "roster-list" ]
                                    (List.map
                                        (\vote ->
                                            li []
                                                [ bdi [] [ text vote.creator.apId ]
                                                , text " · "
                                                , text
                                                    (if vote.isUpvote then
                                                        Translations.upvotesLabel active.texts

                                                     else
                                                        Translations.downvotesLabel active.texts
                                                    )
                                                ]
                                        )
                                        page.items
                                    )
                        )
                    , button [ A.type_ "button", A.class "text-button", Events.onClick config.onCloseVotes ]
                        [ text (Translations.closeLabel active.texts) ]
                    ]
                ]


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
    { model
        | post = NotAsked
        , replies = NotAsked
        , crossPosts = []
        , expandedReplies = Set.empty
        , busy = Set.empty
        , focusComment = Nothing
        , voteDialog = Nothing
    }


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
        Route.Post postId _ ->
            Api.get
                ("/comment/list?post_id="
                    ++ urlEncode (String.fromInt postId)
                    ++ "&limit=20&sort="
                    ++ sort
                    ++ "&max_depth="
                    ++ String.fromInt maxDepth
                )
                RepliesLoaded

        _ ->
            Cmd.none
    )


load : Int -> Maybe Int -> Url -> Model -> ( Model, Cmd Msg )
load id commentId url model =
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
    ( { model
        | post = Loading
        , replies = Loading
        , crossPosts = []
        , expandedReplies = Set.empty
        , focusComment = Maybe.map String.fromInt commentId
        , voteDialog = Nothing
      }
    , Cmd.batch
        [ Api.get ("/post?id=" ++ urlEncode (String.fromInt id)) PostLoaded
        , Api.get
            ("/comment/list?post_id="
                ++ urlEncode (String.fromInt id)
                ++ "&limit=20&sort="
                ++ sort
                ++ "&max_depth="
                ++ String.fromInt maxDepth
                ++ cursorQuery url
            )
            RepliesLoaded
        ]
    )
