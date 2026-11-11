module Feature.Notifications exposing (Action(..), Config, Model, Msg(..), Outcome, initial, load, notificationItem, notificationKind, pageNotifications, unread, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, div, li, p, section, span, strong, text, time, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewRemote)
import Ui.Formatting exposing (Formatting)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)


type alias Model =
    { notifications : Remote (Domain.Page Domain.NotificationView), unreadCount : Maybe String }


initial : Model
initial =
    { notifications = NotAsked, unreadCount = Nothing }


type Msg
    = MarkNoticeRead String
    | MarkAllNoticesRead
    | ActionDone Action Api.Response
    | Loaded Api.Response
    | UnreadLoaded Api.Response


type Action
    = ReadNoticeAction String
    | ReadAllAction


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { notifications : Remote (Domain.Page Domain.NotificationView), unreadCount : Maybe String, flash : Flash, sessionProblem : Maybe Api.Problem }


update : String -> Url -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf url message state =
    let
        ( next, command ) =
            updateWorking csrf url message { notifications = state.notifications, unreadCount = state.unreadCount, flash = NoFlash, sessionProblem = Nothing }
    in
    ( { notifications = next.notifications, unreadCount = next.unreadCount }, command, { flash = next.flash, sessionProblem = next.sessionProblem } )


load : Url -> Cmd Msg
load url =
    Cmd.batch [ Api.get ("/account/notification/list?limit=20" ++ cursorQuery url) Loaded, unread ]


unread : Cmd Msg
unread =
    Api.get "/account/unread_counts" UnreadLoaded


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


updateWorking : String -> Url -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf url message model =
    case message of
        MarkNoticeRead id ->
            ( model
            , Api.send csrf
                "POST"
                "/account/notification/mark_as_read"
                (Encode.encode 0 (Encode.object [ ( "notification_id", Encode.int (String.toInt id |> Maybe.withDefault 0) ), ( "read", Encode.bool True ) ]))
                (ActionDone (ReadNoticeAction id))
            )

        MarkAllNoticesRead ->
            case model.notifications of
                Ready page ->
                    ( model
                    , Api.send csrf
                        "POST"
                        "/account/notification/mark_as_read/all"
                        ""
                        (ActionDone ReadAllAction)
                    )

                _ ->
                    ( model, Cmd.none )

        ActionDone action response ->
            case action of
                ReadNoticeAction id ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( model, load url )

                        Err problem ->
                            ( problemState model problem, Cmd.none )

                ReadAllAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( model, load url )

                        Err problem ->
                            ( problemState model problem, Cmd.none )

        Loaded response ->
            case Api.decodeResponse (Domain.page Domain.notificationView) response of
                Ok page ->
                    ( { model | notifications = Ready page }, Cmd.none )

                Err problem ->
                    ( { model
                        | notifications = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        UnreadLoaded response ->
            case Api.decodeResponse (Decode.field "notification_count" Decode.int) response of
                Ok count ->
                    ( { model | unreadCount = Just (String.fromInt count) }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


cursorQuery : Url -> String
cursorQuery url =
    case Route.cursor url of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


type alias Config msg =
    { retry : msg
    , markNoticeRead : String -> msg
    , markAllNoticesRead : msg
    }


type alias ViewModel =
    { unreadCount : Maybe String
    , notifications : Remote (Domain.Page Domain.NotificationView)
    , auth : AuthState
    , formatted : Maybe Formatting
    , url : Url
    }


pageNotifications : Config msg -> ViewModel -> Active -> Html msg
pageNotifications config model active =
    pageHeading (Translations.notificationsTitle active.texts)
        (section [ A.class "primary-column" ]
            [ case model.auth of
                Authenticated _ ->
                    div [ A.class "actions" ]
                        [ button [ A.class "outlined-button", Events.onClick config.markAllNoticesRead ]
                            [ text (Translations.markAllRead active.texts) ]
                        , case model.unreadCount of
                            Just count ->
                                span [ A.class "chip notification-unread-summary" ] [ text (Translations.unreadNotifications count active.texts) ]

                            Nothing ->
                                text ""
                        ]

                _ ->
                    loginRequired active.texts
            , viewRemote config.retry
                active.texts
                model.notifications
                (\page ->
                    if List.isEmpty page.items then
                        div [ A.class "stack" ]
                            [ p [ A.class "muted" ] [ text (Translations.noNotifications active.texts) ]
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "notification-list" ] (List.map (notificationItem config model active) page.items)
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]
                )
            ]
        )


notificationItem : Config msg -> ViewModel -> Active -> Domain.NotificationView -> Html msg
notificationItem config model active notice =
    let
        value =
            notice.notification

        noticeId =
            String.fromInt value.id
    in
    li [ A.class "card" ]
        [ p [] [ strong [] [ bdi [] [ text (noticeActor notice) ] ], text " ", text (notificationKind active.texts value.kind) ]
        , p [ A.class "metadata" ] [ time [ A.datetime value.publishedAt, A.attribute "data-commune-time" "" ] [ text value.publishedAt ] ]
        , div [ A.class "actions" ]
            [ notificationTargetLink active notice
            , if value.read then
                text ""

              else
                button [ A.class "text-button", Events.onClick (config.markNoticeRead noticeId) ]
                    [ text (Translations.markRead active.texts) ]
            ]
        ]


notificationTargetLink : Active -> Domain.NotificationView -> Html msg
notificationTargetLink active notice =
    case notice.data of
        Domain.NotificationComment comment ->
            a
                [ A.href (Route.path (Route.Post comment.post.id (Just comment.comment.id))) ]
                [ text (Translations.repliesTitle active.texts) ]

        Domain.NotificationPost post ->
            a [ A.href (Route.path (Route.Post post.post.id Nothing)) ]
                [ text (Translations.repliesTitle active.texts) ]

        Domain.NotificationModAction modlog ->
            a [ A.href (Route.path (Route.Modlog Nothing)) ]
                [ text (Translations.notificationModeration active.texts) ]

        Domain.NotificationPrivateMessage _ ->
            span [ A.class "muted" ] [ text (Translations.notificationOther active.texts) ]


noticeActor : Domain.NotificationView -> String
noticeActor notice =
    case notice.data of
        Domain.NotificationComment comment ->
            comment.creator.apId

        Domain.NotificationPost post ->
            post.creator.apId

        Domain.NotificationModAction modlog ->
            Maybe.withDefault "" (Maybe.map .apId modlog.moderator)

        Domain.NotificationPrivateMessage _ ->
            ""


notificationKind : Translations.I18n -> Domain.NotificationKind -> String
notificationKind texts kind =
    case kind of
        Domain.ReplyNotification ->
            Translations.notificationReply texts

        Domain.MentionNotification ->
            Translations.notificationMention texts

        Domain.ModActionNotification ->
            Translations.notificationModeration texts

        Domain.PrivateMessageNotification ->
            Translations.notificationOther texts

        Domain.SubscribedNotification ->
            Translations.notificationOther texts

        Domain.UnknownNotificationKind _ ->
            Translations.notificationOther texts
