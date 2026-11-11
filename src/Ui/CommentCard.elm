module Ui.CommentCard exposing (Config, commentCard)

import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, details, div, h2, p, span, summary, text, time)
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
    , canAct : Bool
    , canViewVotes : Bool
    , isBusy : String -> Bool
    , isExpanded : String -> Bool
    , onVote : String -> Int -> msg
    , onSave : String -> Bool -> msg
    , onReport : String -> msg
    , canReport : Bool
    , onDelete : String -> msg
    , onToggle : String -> msg
    , onBlockAuthor : Int -> Bool -> msg
    , onRemoveComment : String -> Bool -> msg
    , onLockComment : String -> Bool -> msg
    , onDistinguishComment : String -> Bool -> msg
    , onViewVotes : String -> msg
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

        owner =
            config.viewerActor == Just view.creator.apId

        blockedAuthor =
            Maybe.andThen .blockedAt view.personActions /= Nothing

        secondary =
            config.canAct || view.canMod
    in
    article
        [ A.id ("comment-" ++ commentId)
        , A.class "card comment-card"
        , A.tabindex -1
        , A.attribute "aria-labelledby" ("comment-heading-" ++ commentId)
        ]
        [ h2 [ A.id ("comment-heading-" ++ commentId), A.dir "auto" ]
            [ a [ A.href (Route.path (Route.Profile (Domain.profileHandle view.creator))) ]
                [ bdi [] [ text (Translations.authorLabel authorText texts) ] ]
            ]
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
            , if owner || view.canMod then
                a
                    [ A.class "icon-button"
                    , A.href (Route.path (Route.EditComment comment.id))
                    , A.attribute "aria-label" (Translations.editComment texts)
                    , A.attribute "title" (Translations.editComment texts)
                    ]
                    [ Ui.Icon.view Ui.Icon.Edit ]

              else
                text ""
            , if owner || view.canMod then
                button
                    [ A.class "icon-button danger-text"
                    , A.attribute "aria-label" (Translations.deletePost texts)
                    , A.attribute "title" (Translations.deletePost texts)
                    , Events.onClick (config.onDelete commentId)
                    ]
                    [ Ui.Icon.view Ui.Icon.Delete ]

              else
                text ""
            , if secondary then
                details [ A.class "action-menu" ]
                    [ summary [ A.class "text-button" ] [ text (Translations.moderationAction texts) ]
                    , div [ A.class "action-menu-items" ]
                        [ if config.canAct && config.viewerId /= Just view.creator.id then
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
                        , if view.canMod then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onRemoveComment commentId (not comment.removed)) ]
                                [ text
                                    (if comment.removed then
                                        Translations.restore texts

                                     else
                                        Translations.remove texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onLockComment commentId (not comment.locked)) ]
                                [ text
                                    (if comment.locked then
                                        Translations.unlockPost texts

                                     else
                                        Translations.lockPost texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod then
                            button [ A.type_ "button", A.class "text-button", Events.onClick (config.onDistinguishComment commentId (not comment.distinguished)) ]
                                [ text
                                    (if comment.distinguished then
                                        Translations.undistinguishComment texts

                                     else
                                        Translations.distinguishComment texts
                                    )
                                ]

                          else
                            text ""
                        , if view.canMod || config.canViewVotes then
                            button
                                [ A.id ("view-votes-comment-" ++ commentId)
                                , A.type_ "button"
                                , A.class "text-button"
                                , Events.onClick (config.onViewVotes commentId)
                                ]
                                [ text (Translations.viewVotes texts) ]

                          else
                            text ""
                        ]
                    ]

              else
                text ""
            ]
        , if config.isExpanded commentId then
            config.nested commentId

          else
            text ""
        ]
