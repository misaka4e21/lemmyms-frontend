module App.View.Content exposing (editorConfig, pageCommentTarget, pageCommunities, pageCommunity, pageCreatePost, pageLatest, pagePost, pageSearch, postCard)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser
import Feature.Community as Community
import Feature.Editor.State exposing (EditorMode(..))
import Feature.Editor.Update as Editor
import Feature.Editor.View
import Feature.Feed as Feed
import Feature.Post as Post
import Feature.Report as Report
import Feature.Search as Search
import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, h2, p, text)
import Html.Attributes as A
import Lemmy.Domain as Domain
import Lemmy.Markdown
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Set exposing (Set)
import Ui.CommentCard
import Ui.Layout exposing (pageHeading)
import Ui.ListingControls
import Ui.PostCard
import Url exposing (Url)


postCard : Model -> Active -> Domain.PostView -> Html Msg
postCard model active =
    Ui.PostCard.postCard
        { formatted = model.formatted
        , viewerActor =
            case model.auth of
                Authenticated account ->
                    Just (Domain.personApId account)

                _ ->
                    Nothing
        , viewerId = viewerIdOf model
        , blurNsfw = blurNsfwOf model
        , mode = normalizedView (Route.query "view" model.url)
        , isBusy = \id -> Post.isBusy id model.posts.busy
        , isExpanded = \id -> Set.member id model.posts.expandedReplies
        , onLike = \id liked -> PostMessage (Post.ToggleLike id liked)
        , onVote = \id score -> PostMessage (Post.Vote id score)
        , onSave = \id saved -> PostMessage (Post.ToggleSave id saved)
        , onHideForMe = \id hidden -> PostMessage (Post.ToggleHideForMe id hidden)
        , onReport = \id community -> ReportMessage (Report.Open (Report.PostTarget id community))
        , canReport =
            case model.auth of
                Authenticated _ ->
                    True

                _ ->
                    False
        , canAct = isAuthenticated model
        , canViewVotes = canViewVotes model
        , onDelete = OpenDeleteDialog
        , onReplies = PostMessage << Post.ToggleReplies
        , onMarkRead = \id read -> PostMessage (Post.SetRead id read)
        , onBlockAuthor = \id block -> PostMessage (Post.BlockPerson id block)
        , onBlockCommunity = \id block -> PostMessage (Post.BlockCommunity id block)
        , onRemovePost = \id remove -> PostMessage (Post.ModeratePost id (Post.RemovePostAction remove))
        , onLockPost = \id lock -> PostMessage (Post.ModeratePost id (Post.LockPostAction lock))
        , onFeaturePost = \id feature -> PostMessage (Post.ModeratePost id (Post.FeaturePostAction feature))
        , onViewVotes = \id -> PostMessage (Post.OpenVotes (Post.PostVotes id))
        , nested = \id -> viewNested active id model
        }
        active.texts


threadedPostCard : Model -> Active -> Domain.CommentView -> Html Msg -> Html Msg
threadedPostCard model active comment nested =
    Ui.CommentCard.commentCard
        { formatted = model.formatted
        , viewerActor =
            case model.auth of
                Authenticated account ->
                    Just (Domain.personApId account)

                _ ->
                    Nothing
        , viewerId = viewerIdOf model
        , canAct = isAuthenticated model
        , canViewVotes = canViewVotes model
        , isBusy = \id -> Post.isBusy id model.posts.busy
        , isExpanded = always True
        , onVote = \id score -> PostMessage (Post.CommentVote id score)
        , onSave = \id saved -> PostMessage (Post.CommentSave id saved)
        , onReport = \id -> ReportMessage (Report.Open (Report.CommentTarget id))
        , canReport =
            case model.auth of
                Authenticated _ ->
                    True

                _ ->
                    False
        , onDelete = PostMessage << Post.DeleteComment
        , onToggle = PostMessage << Post.ToggleReplies
        , onBlockAuthor = \id block -> PostMessage (Post.BlockPerson id block)
        , onRemoveComment = \id remove -> PostMessage (Post.ModerateComment id (Post.RemoveCommentAction remove))
        , onLockComment = \id lock -> PostMessage (Post.ModerateComment id (Post.LockCommentAction lock))
        , onDistinguishComment = \id distinguished -> PostMessage (Post.ModerateComment id (Post.DistinguishCommentAction distinguished))
        , onViewVotes = \id -> PostMessage (Post.OpenVotes (Post.CommentVotes id))
        , nested = always nested
        }
        active.texts
        comment


viewerIdOf : Model -> Maybe Int
viewerIdOf model =
    case model.auth of
        Authenticated account ->
            Just account.localUserView.person.id

        _ ->
            Nothing


blurNsfwOf : Model -> Bool
blurNsfwOf model =
    case model.auth of
        Authenticated account ->
            account.localUserView.localUser.blurNsfw

        _ ->
            False


isAuthenticated : Model -> Bool
isAuthenticated model =
    case model.auth of
        Authenticated _ ->
            True

        _ ->
            False


canViewVotes : Model -> Bool
canViewVotes model =
    case model.auth of
        Authenticated account ->
            Domain.isAdmin account

        _ ->
            False


editorConfig : Model -> Feature.Editor.View.Config Msg
editorConfig model =
    { auth = model.auth
    , retry = RetryPage
    , editorTitleChanged = EditorMessage << Editor.EditorTitleChanged
    , editorAuthoring = EditorMessage << Editor.AuthoringMsg
    , editorFormatChanged = EditorMessage << Editor.EditorFormatChanged
    , editorRemoveAttachment = EditorMessage << Editor.EditorRemoveAttachment
    , editorFileSelected = EditorMessage << Editor.EditorFileSelected
    , editorSubmit = EditorMessage Editor.EditorSubmit
    , editorUseLatest = EditorMessage Editor.EditorUseLatest
    , editorKeepDraft = EditorMessage Editor.EditorKeepDraft
    }


pageSearch : Model -> Active -> Html Msg
pageSearch model active =
    Search.pageSearch (searchViewConfig model active) { search = model.searchPage.search, url = model.url } active


searchViewConfig : Model -> Active -> Search.Config Msg
searchViewConfig model active =
    { retry = RetryPage
    , searchKindChanged = SearchMessage << Search.SearchKindChanged
    , searchQueryChanged = SearchMessage << Search.SearchQueryChanged
    , searchSubmitted = SearchMessage Search.SearchSubmitted
    , postCard = postCard model active
    , commentCard = \comment -> threadedPostCard model active comment (text "")
    , personCard = personCard active
    }


personCard : Active -> Domain.PersonView -> Html msg
personCard active personView =
    let
        person =
            personView.person
    in
    article [ A.class "card" ]
        [ h2 [] [ a [ A.href (Route.path (Route.Profile (Domain.profileHandle person))) ] [ text (Domain.displayNameOf person) ] ]
        , p [ A.class "metadata" ] [ bdi [] [ text person.apId ] ]
        , Maybe.withDefault "" person.bio |> Lemmy.Markdown.render
        ]


pagePost : Model -> Active -> String -> Html Msg
pagePost model active postId =
    Post.pagePost
        (postViewConfig model active)
        { post = model.posts.post
        , replies = model.posts.replies
        , crossPosts = model.posts.crossPosts
        , voteDialog = model.posts.voteDialog
        , url = model.url
        }
        active
        postId


pageCreatePost : Model -> Active -> Html Msg
pageCreatePost _ active =
    pageHeading (Translations.publishTopic active.texts)
        (p []
            [ a [ A.href (Route.path Route.Communities) ]
                [ text (Translations.communitiesTitle active.texts) ]
            ]
        )


pageCommentTarget : Model -> Active -> Html Msg
pageCommentTarget model active =
    pageHeading (Translations.repliesTitle active.texts)
        (case model.commentTarget of
            Failed _ ->
                p [ A.id "comment-target-error", A.class "card field-error", A.attribute "role" "alert" ]
                    [ text (Translations.notFound active.texts) ]

            _ ->
                p [ A.class "muted", A.attribute "role" "status" ]
                    [ text (Translations.loadingMessage active.texts) ]
        )


viewNested : Active -> String -> Model -> Html Msg
viewNested active parent _ =
    a [ A.class "outlined-button", A.href (Route.path (Route.Comment (String.toInt parent |> Maybe.withDefault 0))) ]
        [ text (Translations.repliesTitle active.texts) ]


postViewConfig : Model -> Active -> Post.Config Msg
postViewConfig model active =
    { retry = RetryPage
    , postCard = postCard model active
    , threadedPostCard = threadedPostCard model active
    , startReply = EditorMessage << Editor.StartReply
    , editor =
        case model.editorPage.editor of
            Just editor ->
                case editor.mode of
                    CreateReply _ ->
                        Feature.Editor.View.viewEditor (editorConfig model) active editor

                    _ ->
                        text ""

            Nothing ->
                text ""
    , sort =
        Route.query "sort" model.url
            |> (\value ->
                    if List.member value [ "new", "old", "top", "controversial" ] then
                        value

                    else
                        "old"
               )
    , maxDepth =
        Route.query "max_depth" model.url
            |> String.toInt
            |> Maybe.withDefault 6
            |> clamp 1 8
    , sortChanged = PostMessage << Post.SortChanged
    , depthChanged = PostMessage << Post.DepthChanged
    , isExpanded = \id -> Set.member id model.posts.expandedReplies
    , onReplies = PostMessage << Post.ToggleReplies
    , onMarkRead = \id read -> PostMessage (Post.SetRead id read)
    , onBlockAuthor = \id block -> PostMessage (Post.BlockPerson id block)
    , onBlockCommunity = \id block -> PostMessage (Post.BlockCommunity id block)
    , onRemovePost = \id remove -> PostMessage (Post.ModeratePost id (Post.RemovePostAction remove))
    , onLockPost = \id lock -> PostMessage (Post.ModeratePost id (Post.LockPostAction lock))
    , onFeaturePost = \id feature -> PostMessage (Post.ModeratePost id (Post.FeaturePostAction feature))
    , onViewVotes = \id -> PostMessage (Post.OpenVotes (Post.PostVotes id))
    , onCloseVotes = PostMessage Post.CloseVotes
    }


pageLatest : Model -> Active -> Html Msg
pageLatest model active =
    Feed.pageLatest (feedViewConfig model active) { topics = model.feed.topics, url = model.url } active


feedViewConfig : Model -> Active -> Feed.Config Msg
feedViewConfig model active =
    { retry = RetryPage
    , listingControls = listingControls model active
    , postCard = postCard model active
    }


pageCommunities : Model -> Active -> Html Msg
pageCommunities model active =
    Community.pageCommunities (communityViewConfig model active) (communityViewModel model) active


pageCommunity : Model -> Active -> String -> Html Msg
pageCommunity model active id =
    Community.pageCommunity (communityViewConfig model active) (communityViewModel model) active id


communityViewConfig : Model -> Active -> Community.Config Msg
communityViewConfig model active =
    { retry = RetryPage
    , listingControls = listingControls model active
    , notificationChanged = CommunityMessage << Community.NotificationModeChanged
    , postCard = postCard model active
    , toggleFollow = CommunityMessage << Community.ToggleFollow
    , reportCommunity = \id -> ReportMessage (Report.Open (Report.CommunityTarget id))
    }


communityViewModel : Model -> Community.ViewModel
communityViewModel model =
    { communities = model.communityPage.communities
    , community = model.communityPage.community
    , communityTopics = model.communityPage.communityTopics
    , moderators = model.communityPage.moderators
    , notificationBusy = model.communityPage.notificationBusy
    , busy = model.communityPage.busy
    , problem = model.communityPage.problem
    , auth = model.auth
    , url = model.url
    }


listingControls : Model -> Active -> Html Msg
listingControls model active =
    Ui.ListingControls.view active.texts
        { listing = Route.listing "local" model.url
        , sort = Route.sort "active" model.url
        , timeRange = Route.query "time_range" model.url
        , viewMode = normalizedView (Route.query "view" model.url)
        , listingChanged = \value -> Navigate (Browser.Internal (urlFor "type" value model.url))
        , sortChanged = \value -> Navigate (Browser.Internal (urlFor "sort" value model.url))
        , timeRangeChanged = \value -> Navigate (Browser.Internal (urlFor "time_range" value model.url))
        , viewModeChanged = \value -> Navigate (Browser.Internal (urlFor "view" value model.url))
        }


urlFor : String -> String -> Url -> Url
urlFor name value url =
    Route.withQueryUrl name value url


normalizedView : String -> String
normalizedView value =
    if List.member value [ "list", "card", "small_card" ] then
        value

    else
        "card"
