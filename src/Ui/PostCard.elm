module Ui.PostCard exposing (Config, deleteTriggerId, postCard)

import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, div, h2, h3, p, section, span, text, time)
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
    , isBusy : String -> Bool
    , isExpanded : String -> Bool
    , onVote : String -> Int -> msg
    , onLike : String -> Bool -> msg
    , onSave : String -> Bool -> msg
    , onHideForMe : String -> Bool -> msg
    , onReport : String -> String -> msg
    , canReport : Bool
    , onDelete : String -> msg
    , onReplies : String -> msg
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
    in
    article [ A.class "card post-card", A.attribute "aria-labelledby" ("post-" ++ postId) ]
        [ h2 [ A.id ("post-" ++ postId), A.dir "auto" ]
            [ a [ A.href (Route.path (Route.Post post.id Nothing)) ] [ text post.name ] ]
        , p [ A.class "metadata" ]
            [ bdi [] [ text (Translations.authorLabel authorText texts) ]
            , text " · "
            , time [ A.datetime post.publishedAt, A.attribute "data-commune-time" "" ] [ text post.publishedAt ]
            ]
        , Maybe.withDefault "" post.body |> Markdown.render
        , linkSection texts post.url
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
            , if saved view then
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" saveName
                    , A.attribute "title" saveName
                    , A.attribute "aria-pressed" "true"
                    , A.disabled (config.isBusy postId)
                    , Events.onClick (config.onSave postId True)
                    ]
                    [ Ui.Icon.view (Ui.Icon.Bookmark True) ]

              else
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" saveName
                    , A.attribute "title" saveName
                    , A.attribute "aria-pressed" "false"
                    , A.disabled (config.isBusy postId)
                    , Events.onClick (config.onSave postId False)
                    ]
                    [ Ui.Icon.view (Ui.Icon.Bookmark False) ]
            , button
                [ A.class "icon-button"
                , A.attribute "aria-label" hideName
                , A.attribute "title" hideName
                , A.attribute "aria-pressed" (boolText (hidden view))
                , A.disabled (config.isBusy postId)
                , Events.onClick (config.onHideForMe postId (hidden view))
                ]
                [ Ui.Icon.view (Ui.Icon.Hide (hidden view)) ]
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
            ]
        , if config.isExpanded postId then
            config.nested postId

          else
            text ""
        ]


saved : Domain.PostView -> Bool
saved view =
    Maybe.andThen .savedAt view.postActions /= Nothing


hidden : Domain.PostView -> Bool
hidden view =
    Maybe.andThen .hiddenAt view.postActions /= Nothing


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


deleteTriggerId : String -> String
deleteTriggerId id =
    "delete-post-" ++ id
