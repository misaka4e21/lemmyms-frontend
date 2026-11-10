module Ui.CommentCard exposing (Config, commentCard)

import Generated.I18n as Translations
import Html exposing (Html, article, bdi, button, div, h2, p, span, text, time)
import Html.Attributes as A
import Html.Events as Events
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Ui.Formatting exposing (Formatting, boolText, formattedCount, repliesLabel)
import Ui.Icon
import Ui.VoteControl


type alias Config msg =
    { formatted : Maybe Formatting
    , viewerActor : Maybe String
    , isBusy : String -> Bool
    , isExpanded : String -> Bool
    , onVote : String -> Int -> msg
    , onSave : String -> Bool -> msg
    , onReport : String -> msg
    , canReport : Bool
    , onToggle : String -> msg
    , nested : String -> Html msg
    }


commentCard : Config msg -> Translations.I18n -> Domain.CommentView -> Html msg
commentCard config texts view =
    let
        comment =
            view.comment

        commentId =
            String.fromInt comment.id

        authorText =
            Domain.displayNameOf view.creator ++ " (" ++ Domain.acctOf view.creator ++ ")"

        vote =
            Maybe.andThen .voteIsUpvote view.commentActions

        votedByMe =
            case vote of
                Just True ->
                    1

                Just False ->
                    -1

                Nothing ->
                    0

        saved =
            Maybe.andThen .savedAt view.commentActions /= Nothing

        replyName =
            repliesLabel config.formatted texts comment.childCount
    in
    article [ A.class "card comment-card", A.attribute "aria-labelledby" ("comment-" ++ commentId) ]
        [ h2 [ A.id ("comment-" ++ commentId), A.dir "auto" ] [ bdi [] [ text (Translations.authorLabel authorText texts) ] ]
        , p [ A.class "metadata" ]
            [ time [ A.datetime comment.publishedAt, A.attribute "data-commune-time" "" ] [ text comment.publishedAt ]
            ]
        , Markdown.render comment.content
        , div [ A.class "post-actions" ]
            [ Ui.VoteControl.view
                { formatted = config.formatted
                , score = comment.score
                , upvotes = comment.upvotes
                , downvotes = comment.downvotes
                , votedByMe = votedByMe
                , canUpvote = True
                , canDownvote = True
                , canLike = True
                , busy = config.isBusy commentId
                , onVote = config.onVote commentId
                , onLike = \_ -> config.onVote commentId 1
                }
                texts
            , button
                [ A.class "icon-button"
                , A.attribute "aria-label"
                    (if saved then
                        Translations.unsavePost texts

                     else
                        Translations.savePost texts
                    )
                , A.attribute "title"
                    (if saved then
                        Translations.unsavePost texts

                     else
                        Translations.savePost texts
                    )
                , A.attribute "aria-pressed" (boolText saved)
                , A.disabled (config.isBusy commentId)
                , Events.onClick (config.onSave commentId saved)
                ]
                [ Ui.Icon.view (Ui.Icon.Bookmark saved) ]
            , if comment.childCount > 0 then
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" replyName
                    , A.attribute "title" replyName
                    , A.attribute "aria-expanded" (boolText (config.isExpanded commentId))
                    , Events.onClick (config.onToggle commentId)
                    ]
                    [ Ui.Icon.view Ui.Icon.Reply
                    , span [ A.class "action-count" ] [ text (formattedCount config.formatted comment.childCount) ]
                    ]

              else
                text ""
            , if config.canReport then
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" (Translations.reportPost texts)
                    , A.attribute "title" (Translations.reportPost texts)
                    , Events.onClick (config.onReport commentId)
                    ]
                    [ Ui.Icon.view Ui.Icon.Report ]

              else
                text ""
            ]
        , if config.isExpanded commentId then
            config.nested commentId

          else
            text ""
        ]
