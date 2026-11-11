module Ui.PostCard exposing (Config, deleteTriggerId, postCard)

import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, details, div, h2, h3, img, p, section, span, summary, text, time)
import Html.Attributes as A
import Html.Events as Events
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Lemmy.Route as Route
import Ui.Formatting exposing (Formatting, boolText, formattedCount, repliesLabel)
import Ui.Icon
import Ui.VoteControl


type alias Config msg =
    { formatted : Maybe Formatting
    , viewerActor : Maybe String
    , viewerId : Maybe Int
    , blurNsfw : Bool
    , mode : String
    , isBusy : String -> Bool
    , isExpanded : String -> Bool
    , canAct : Bool
    , canViewVotes : Bool
    , onVote : String -> Int -> msg
    , onLike : String -> Bool -> msg
    , onSave : String -> Bool -> msg
    , onHideForMe : String -> Bool -> msg
    , onReport : String -> String -> msg
    , canReport : Bool
    , onDelete : String -> msg
    , onReplies : String -> msg
    , onMarkRead : String -> Bool -> msg
    , onBlockAuthor : Int -> Bool -> msg
    , onBlockCommunity : Int -> Bool -> msg
    , onRemovePost : String -> Bool -> msg
    , onLockPost : String -> Bool -> msg
    , onFeaturePost : String -> Bool -> msg
    , onViewVotes : String -> msg
    , nested : String -> Html msg
    }


postCard : Config msg -> Translations.I18n -> Domain.PostView -> Html msg
postCard config texts view =
    let
        post =
            view.post

        postId =
            String.fromInt post.id

        authorText =
            Domain.displayNameOf view.creator ++ " (" ++ Domain.acctOf view.creator ++ ")"

        replyName =
            repliesLabel config.formatted texts post.comments

        saveName =
            if saved view then
                Translations.unsavePost texts

            else
                Translations.savePost texts

        hideName =
            if hidden view then
                Translations.unhideForMe texts

            else
                Translations.hideForMe texts

        vote =
            Maybe.andThen .voteIsUpvote view.postActions

        votedByMe =
            case vote of
                Just True ->
                    1

                Just False ->
                    -1

                Nothing ->
                    0

        owner =
            config.viewerActor == Just view.creator.apId

        read =
            Maybe.andThen .readAt view.postActions /= Nothing

        blockedAuthor =
            Maybe.andThen .blockedAt view.personActions /= Nothing

        blockedCommunity =
            Maybe.andThen .blockedAt view.communityActions /= Nothing

        secondary =
            config.canAct || view.canMod
    in
    article
        [ A.id ("post-" ++ postId)
        , A.class ("card post-card post-card-" ++ normalizedMode config.mode)
        , A.attribute "aria-labelledby" ("post-heading-" ++ postId)
        ]
        [ h2 [ A.id ("post-heading-" ++ postId), A.dir "auto" ]
            [ a [ A.href (Route.path (Route.Post post.id Nothing)) ] [ text post.name ] ]
        , p [ A.class "metadata" ]
            [ bdi []
                [ a [ A.href (Route.path (Route.Profile view.creator.name)) ] [ text authorText ] ]
            , text " · "
            , a [ A.href (Route.path (Route.Community view.community.name)) ]
                [ text (Maybe.withDefault view.community.name view.community.title) ]
            , text " · "
            , time [ A.datetime post.publishedAt, A.attribute "data-commune-time" "" ] [ text post.publishedAt ]
            ]
        , tagsRow texts view.tags
        , nsfwGate config texts post
        , div [ A.class "post-actions" ]
            [ Ui.VoteControl.view
                { formatted = config.formatted
                , score = post.score
                , upvotes = post.upvotes
                , downvotes = post.downvotes
                , votedByMe = votedByMe
                , canUpvote = view.community.postUpvotes /= Domain.DisabledVotes
                , canDownvote = view.community.postDownvotes /= Domain.DisabledVotes
                , canLike = True
                , busy = config.isBusy postId
                , onVote = config.onVote postId
                , onLike = config.onLike postId
                }
                texts
            , toggleButton config texts postId saveName (saved view) (config.onSave postId (not (saved view))) (Ui.Icon.Bookmark (saved view))
            , toggleButton config texts postId hideName (hidden view) (config.onHideForMe postId (not (hidden view))) (Ui.Icon.Hide (hidden view))
            , if config.canReport && not post.deleted then
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" (Translations.reportPost texts)
                    , A.attribute "title" (Translations.reportPost texts)
                    , Events.onClick (config.onReport postId (String.fromInt post.communityId))
                    ]
                    [ Ui.Icon.view Ui.Icon.Report ]

              else
                text ""
            , if owner || view.canMod then
                a
                    [ A.class "icon-button"
                    , A.href (Route.path (Route.EditPost post.id))
                    , A.attribute "aria-label" (Translations.editPost texts)
                    , A.attribute "title" (Translations.editPost texts)
                    ]
                    [ Ui.Icon.view Ui.Icon.Edit ]

              else
                text ""
            , if owner then
                button
                    [ A.id (deleteTriggerId postId)
                    , A.class "icon-button danger-text"
                    , A.attribute "aria-label" (Translations.deletePost texts)
                    , A.attribute "title" (Translations.deletePost texts)
                    , Events.onClick (config.onDelete postId)
                    ]
                    [ Ui.Icon.view Ui.Icon.Delete ]

              else
                text ""
            , if post.comments > 0 then
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" replyName
                    , A.attribute "title" replyName
                    , A.attribute "aria-expanded" (boolText (config.isExpanded postId))
                    , Events.onClick (config.onReplies postId)
                    ]
                    [ Ui.Icon.view Ui.Icon.Reply
                    , span [ A.class "action-count" ] [ text (formattedCount config.formatted post.comments) ]
                    ]

              else
                text ""
            , if secondary then
                details [ A.class "action-menu" ]
                    [ summary [ A.class "text-button" ] [ text (Translations.moderationAction texts) ]
                    , div [ A.class "action-menu-items" ]
                        [ if config.canAct then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onMarkRead postId (not read)) ]
                                [ text
                                    (if read then
                                        Translations.markUnread texts

                                     else
                                        Translations.markRead texts
                                    )
                                ]

                          else
                            text ""
                        , if config.canAct && config.viewerId /= Just view.creator.id then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onBlockAuthor view.creator.id (not blockedAuthor)) ]
                                [ text
                                    (if blockedAuthor then
                                        Translations.unblockAuthor texts

                                     else
                                        Translations.blockAuthor texts
                                    )
                                ]

                          else
                            text ""
                        , if config.canAct then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onBlockCommunity view.community.id (not blockedCommunity)) ]
                                [ text
                                    (if blockedCommunity then
                                        Translations.unblockCommunityAction texts

                                     else
                                        Translations.blockCommunityAction texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onRemovePost postId (not post.removed)) ]
                                [ text
                                    (if post.removed then
                                        Translations.restore texts

                                     else
                                        Translations.remove texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onLockPost postId (not post.locked)) ]
                                [ text
                                    (if post.locked then
                                        Translations.unlockPost texts

                                     else
                                        Translations.lockPost texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onFeaturePost postId (not post.featuredCommunity)) ]
                                [ text
                                    (if post.featuredCommunity then
                                        Translations.unfeaturePost texts

                                     else
                                        Translations.featurePost texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod || config.canViewVotes then
                            button
                                [ A.id ("view-votes-post-" ++ postId)
                                , A.type_ "button"
                                , A.class "text-button"
                                , Events.onClick (config.onViewVotes postId)
                                ]
                                [ text (Translations.viewVotes texts) ]

                          else
                            text ""
                        ]
                    ]

              else
                text ""
            ]
        , if config.isExpanded postId then
            config.nested postId

          else
            text ""
        ]


toggleButton : Config msg -> Translations.I18n -> String -> String -> Bool -> msg -> Ui.Icon.Icon -> Html msg
toggleButton config texts postId labelText pressed click icon =
    button
        [ A.class "icon-button"
        , A.attribute "aria-label" labelText
        , A.attribute "title" labelText
        , A.attribute "aria-pressed" (boolText pressed)
        , A.disabled (config.isBusy postId)
        , Events.onClick click
        ]
        [ Ui.Icon.view icon ]


nsfwGate : Config msg -> Translations.I18n -> Domain.Post -> Html msg
nsfwGate config texts post =
    if post.nsfw && config.blurNsfw then
        details [ A.class "nsfw-gate" ]
            [ summary [ A.class "text-button" ] [ text (Translations.showNsfw texts) ]
            , content texts post
            ]

    else
        content texts post


content : Translations.I18n -> Domain.Post -> Html msg
content texts post =
    div [ A.class "post-content" ]
        [ case post.thumbnailUrl of
            Just thumbnail ->
                img
                    [ A.class "post-thumbnail"
                    , A.src thumbnail
                    , A.alt (Maybe.withDefault "" post.altText)
                    , A.attribute "referrerpolicy" "no-referrer"
                    ]
                    []

            Nothing ->
                text ""
        , Maybe.withDefault "" post.body |> Markdown.render
        , linkSection texts post.url
        ]


tagsRow : Translations.I18n -> List Domain.CommunityTag -> Html msg
tagsRow texts tags =
    if List.isEmpty tags then
        text ""

    else
        p [ A.class "chips" ]
            (List.map
                (\tag ->
                    span [ A.class "chip" ]
                        [ text (Maybe.withDefault tag.name tag.displayName) ]
                )
                tags
            )


linkSection : Translations.I18n -> Maybe String -> Html msg
linkSection texts url =
    case url of
        Just value ->
            section [ A.class "attachments" ]
                [ h3 [] [ text (Translations.attachments texts) ]
                , a [ A.href value, A.rel "noopener noreferrer" ] [ text value ]
                ]

        Nothing ->
            text ""


saved : Domain.PostView -> Bool
saved view =
    Maybe.andThen .savedAt view.postActions /= Nothing


hidden : Domain.PostView -> Bool
hidden view =
    Maybe.andThen .hiddenAt view.postActions /= Nothing


normalizedMode : String -> String
normalizedMode value =
    if List.member value [ "list", "card", "small_card" ] then
        value

    else
        "card"


deleteTriggerId : String -> String
deleteTriggerId id =
    "delete-post-" ++ id
