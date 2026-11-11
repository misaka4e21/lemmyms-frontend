module Feature.Notifications exposing (Action(..), Config, Model, Msg(..), Outcome, initial, load, loadComposer, notificationItem, notificationKind, pageComposer, pageNotifications, startLoading, unread, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Feature.Authoring.State as AuthoringState
import Feature.Authoring.Update as Authoring
import Feature.Authoring.View as AuthoringView
import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, div, form, h2, label, li, nav, p, section, span, strong, text, textarea, time, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Set exposing (Set)
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (Formatting)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)


type alias Composer =
    { recipientId : Int
    , recipient : Remote Domain.PersonView
    , authoring : AuthoringState.Model
    , sending : Bool
    , localProblem : Maybe String
    , problem : Maybe Api.Problem
    }


type alias EditingMessage =
    { id : Int, content : String }


type alias Model =
    { notifications : Remote (Domain.Page Domain.NotificationView)
    , unreadCount : Maybe String
    , composer : Composer
    , editingMessage : Maybe EditingMessage
    , messageBusy : Set String
    , messageProblem : Maybe Api.Problem
    }


emptyComposer : Int -> Composer
emptyComposer recipientId =
    { recipientId = recipientId
    , recipient = NotAsked
    , authoring = AuthoringState.init "private-message-body" ""
    , sending = False
    , localProblem = Nothing
    , problem = Nothing
    }


updateComposer : (Composer -> Composer) -> { a | composer : Composer } -> { a | composer : Composer }
updateComposer change model =
    { model | composer = change model.composer }


initial : Model
initial =
    { notifications = NotAsked
    , unreadCount = Nothing
    , composer = emptyComposer 0
    , editingMessage = Nothing
    , messageBusy = Set.empty
    , messageProblem = Nothing
    }


startLoading : Model -> Model
startLoading model =
    { model | notifications = Loading, unreadCount = Nothing }


type Msg
    = MarkNoticeRead String
    | MarkAllNoticesRead
    | ActionDone Action Api.Response
    | Loaded Api.Response
    | UnreadLoaded Api.Response
    | ComposerRecipientLoaded Api.Response
    | ComposerAuthoring Authoring.Msg
    | SendMessage
    | MessageSent Api.Response
    | StartMessageEdit Int String
    | MessageEditChanged String
    | CancelMessageEdit
    | SaveMessage Int
    | DeleteMessage Int
    | MessageActionDone MessageAction Api.Response


type Action
    = ReadNoticeAction String
    | ReadAllAction


type MessageAction
    = SaveMessageAction Int
    | DeleteMessageAction Int


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem, navigation : Maybe String }


type alias Working =
    { notifications : Remote (Domain.Page Domain.NotificationView)
    , unreadCount : Maybe String
    , composer : Composer
    , editingMessage : Maybe EditingMessage
    , messageBusy : Set String
    , messageProblem : Maybe Api.Problem
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    }


update : String -> Url -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf url message state =
    let
        ( next, command ) =
            updateWorking csrf
                url
                message
                { notifications = state.notifications
                , unreadCount = state.unreadCount
                , composer = state.composer
                , editingMessage = state.editingMessage
                , messageBusy = state.messageBusy
                , messageProblem = state.messageProblem
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                }
    in
    ( { notifications = next.notifications
      , unreadCount = next.unreadCount
      , composer = next.composer
      , editingMessage = next.editingMessage
      , messageBusy = next.messageBusy
      , messageProblem = next.messageProblem
      }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem, navigation = next.navigation }
    )


load : Url -> Cmd Msg
load url =
    Cmd.batch [ Api.get (notificationQuery url) Loaded, unread ]


loadComposer : Int -> Model -> ( Model, Cmd Msg )
loadComposer recipientId model =
    ( { model
        | composer =
            let
                composer =
                    emptyComposer recipientId
            in
            { composer | recipient = Loading }
      }
    , Api.get ("/person?person_id=" ++ String.fromInt recipientId) ComposerRecipientLoaded
    )


unread : Cmd Msg
unread =
    Api.get "/account/unread_counts" UnreadLoaded


notificationQuery : Url -> String
notificationQuery url =
    let
        filter =
            if Route.query "kind" url == "messages" then
                "&type_=private_message"

            else
                ""
    in
    "/account/notification/list?limit=20" ++ filter ++ cursorQuery url


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
                Ready _ ->
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
                ReadNoticeAction _ ->
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

        ComposerRecipientLoaded response ->
            case Api.decodeResponse (Decode.field "person_view" Domain.personView) response of
                Ok personView ->
                    ( updateComposer (\composer -> { composer | recipient = Ready personView, localProblem = Nothing, problem = Nothing }) model
                    , Cmd.none
                    )

                Err problem ->
                    ( updateComposer (\composer -> { composer | recipient = Failed problem }) model, Cmd.none )

        ComposerAuthoring authoringMessage ->
            let
                ( authoring, command, _ ) =
                    Authoring.update authoringMessage model.composer.authoring
            in
            ( updateComposer (\composer -> { composer | authoring = authoring, localProblem = Nothing, problem = Nothing }) model
            , Cmd.map ComposerAuthoring command
            )

        SendMessage ->
            let
                content =
                    AuthoringState.value model.composer.authoring
            in
            if model.composer.sending then
                ( model, Cmd.none )

            else if String.isEmpty (String.trim content) then
                ( updateComposer (\composer -> { composer | localProblem = Just "required" }) model, Cmd.none )

            else
                case model.composer.recipient of
                    Ready personView ->
                        ( updateComposer (\composer -> { composer | sending = True, localProblem = Nothing, problem = Nothing }) model
                        , Api.send csrf
                            "POST"
                            "/private_message"
                            (Encode.encode 0
                                (Encode.object
                                    [ ( "content", Encode.string content )
                                    , ( "recipient_id", Encode.int personView.person.id )
                                    ]
                                )
                            )
                            MessageSent
                        )

                    _ ->
                        ( model, Cmd.none )

        MessageSent response ->
            case Api.decodeResponse (Decode.field "private_message_view" Domain.privateMessageView) response of
                Ok _ ->
                    let
                        navigation =
                            case model.composer.recipient of
                                Ready personView ->
                                    Just (Route.path (Route.Profile (Domain.profileHandle personView.person)))

                                _ ->
                                    Nothing
                    in
                    ( { model | composer = emptyComposer model.composer.recipientId, flash = FlashMessageSent, navigation = navigation }
                    , Cmd.none
                    )

                Err problem ->
                    let
                        next =
                            updateComposer (\composer -> { composer | sending = False, problem = Just problem }) model
                    in
                    ( { next
                        | flash = FlashProblem problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        StartMessageEdit id content ->
            ( { model | editingMessage = Just { id = id, content = content }, messageProblem = Nothing }, Cmd.none )

        MessageEditChanged content ->
            ( { model | editingMessage = Maybe.map (\value -> { value | content = content }) model.editingMessage }, Cmd.none )

        CancelMessageEdit ->
            ( { model | editingMessage = Nothing }, Cmd.none )

        SaveMessage id ->
            case model.editingMessage of
                Just value ->
                    if Set.member (String.fromInt id) model.messageBusy then
                        ( model, Cmd.none )

                    else
                        ( { model | messageBusy = Set.insert (String.fromInt id) model.messageBusy, messageProblem = Nothing }
                        , Api.send csrf
                            "PUT"
                            "/private_message"
                            (Encode.encode 0
                                (Encode.object
                                    [ ( "private_message_id", Encode.int id )
                                    , ( "content", Encode.string value.content )
                                    ]
                                )
                            )
                            (MessageActionDone (SaveMessageAction id))
                        )

                Nothing ->
                    ( model, Cmd.none )

        DeleteMessage id ->
            if Set.member (String.fromInt id) model.messageBusy then
                ( model, Cmd.none )

            else
                ( { model | messageBusy = Set.insert (String.fromInt id) model.messageBusy, messageProblem = Nothing }
                , Api.send csrf
                    "DELETE"
                    "/private_message"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "private_message_id", Encode.int id )
                            , ( "deleted", Encode.bool True )
                            ]
                        )
                    )
                    (MessageActionDone (DeleteMessageAction id))
                )

        MessageActionDone action response ->
            case action of
                SaveMessageAction id ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model
                                | editingMessage = Nothing
                                , messageBusy = Set.remove (String.fromInt id) model.messageBusy
                                , flash = FlashSaved
                              }
                            , load url
                            )

                        Err problem ->
                            let
                                next =
                                    problemState model problem
                            in
                            ( { next
                                | messageBusy = Set.remove (String.fromInt id) model.messageBusy
                                , messageProblem = Just problem
                              }
                            , Cmd.none
                            )

                DeleteMessageAction id ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model
                                | messageBusy = Set.remove (String.fromInt id) model.messageBusy
                                , flash = FlashDeleted
                              }
                            , load url
                            )

                        Err problem ->
                            let
                                next =
                                    problemState model problem
                            in
                            ( { next
                                | messageBusy = Set.remove (String.fromInt id) model.messageBusy
                                , messageProblem = Just problem
                              }
                            , Cmd.none
                            )


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
    , authoring : Authoring.Msg -> msg
    , sendMessage : msg
    , startEditMessage : Int -> String -> msg
    , messageEditChanged : String -> msg
    , cancelMessageEdit : msg
    , saveMessage : Int -> msg
    , deleteMessage : Int -> msg
    , reportMessage : String -> msg
    }


type alias ViewModel =
    { unreadCount : Maybe String
    , notifications : Remote (Domain.Page Domain.NotificationView)
    , auth : AuthState
    , formatted : Maybe Formatting
    , url : Url
    , composer : Composer
    , editingMessage : Maybe EditingMessage
    , messageBusy : Set String
    , messageProblem : Maybe Api.Problem
    }


pageNotifications : Config msg -> ViewModel -> Active -> Html msg
pageNotifications config model active =
    pageHeading (Translations.notificationsTitle active.texts)
        (section [ A.class "primary-column" ]
            [ filterNav model.url active
            , case model.auth of
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


filterNav : Url -> Active -> Html msg
filterNav url active =
    let
        messagesActive =
            Route.query "kind" url == "messages"
    in
    nav [ A.class "actions", A.attribute "aria-label" (Translations.notificationsTitle active.texts) ]
        [ a
            [ A.class "outlined-button"
            , A.href (Route.path Route.Notifications)
            , A.attribute "aria-current"
                (if messagesActive then
                    "false"

                 else
                    "page"
                )
            ]
            [ text (Translations.allNotifications active.texts) ]
        , a
            [ A.class "outlined-button"
            , A.href (Route.path Route.Notifications ++ "?kind=messages")
            , A.attribute "aria-current"
                (if messagesActive then
                    "page"

                 else
                    "false"
                )
            ]
            [ text (Translations.privateMessages active.texts) ]
        ]


notificationItem : Config msg -> ViewModel -> Active -> Domain.NotificationView -> Html msg
notificationItem config model active notice =
    case notice.data of
        Domain.NotificationPrivateMessage message ->
            privateMessageItem config model active notice message

        _ ->
            genericNotificationItem config model active notice


genericNotificationItem : Config msg -> ViewModel -> Active -> Domain.NotificationView -> Html msg
genericNotificationItem config model active notice =
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


privateMessageItem : Config msg -> ViewModel -> Active -> Domain.NotificationView -> Domain.PrivateMessageView -> Html msg
privateMessageItem config model active notice messageView =
    let
        value =
            notice.notification

        message =
            messageView.privateMessage

        creator =
            messageView.creator

        myId =
            case model.auth of
                Authenticated account ->
                    Just account.localUserView.person.id

                _ ->
                    Nothing

        isCreator =
            myId == Just message.creatorId

        isRecipient =
            myId == Just message.recipientId

        hidden =
            message.deleted || message.deletedByRecipient || message.removed

        editing =
            Maybe.map .id model.editingMessage == Just message.id

        messageId =
            String.fromInt message.id

        busy =
            Set.member messageId model.messageBusy
    in
    li [ A.class "card message-card" ]
        [ article []
            [ h2 [] [ a [ A.href (Route.path (Route.Profile (Domain.profileHandle creator))) ] [ bdi [] [ text (Domain.displayNameOf creator) ] ] ]
            , p [ A.class "metadata" ] [ bdi [] [ text (Domain.acctOf creator) ], text " · ", time [ A.datetime message.publishedAt, A.attribute "data-commune-time" "" ] [ text message.publishedAt ] ]
            , if hidden then
                p [ A.class "muted" ]
                    [ text
                        (if message.removed then
                            Translations.messageRemoved active.texts

                         else
                            Translations.messageDeleted active.texts
                        )
                    ]

              else
                Markdown.render message.content
            , if editing then
                div [ A.class "stack" ]
                    [ label [ A.for ("message-edit-" ++ messageId) ] [ text (Translations.messageBody active.texts) ]
                    , textarea
                        [ A.id ("message-edit-" ++ messageId)
                        , A.value (Maybe.withDefault "" (Maybe.map .content model.editingMessage))
                        , Events.onInput config.messageEditChanged
                        ]
                        []
                    , div [ A.class "actions" ]
                        [ button [ A.class "filled-button", A.disabled busy, Events.onClick (config.saveMessage message.id) ] [ text (Translations.saveMessage active.texts) ]
                        , button [ A.class "text-button", Events.onClick config.cancelMessageEdit ] [ text (Translations.cancel active.texts) ]
                        ]
                    ]

              else
                div [ A.class "actions" ]
                    ([ a [ A.class "text-button", A.href (Route.path (Route.CreatePrivateMessage creator.id)) ] [ text (Translations.reply active.texts) ] ]
                        ++ (if isCreator && not hidden then
                                [ button [ A.class "text-button", Events.onClick (config.startEditMessage message.id message.content) ] [ text (Translations.editMessage active.texts) ] ]

                            else
                                []
                           )
                        ++ (if (isCreator || isRecipient) && not hidden then
                                [ button [ A.class "text-button", A.disabled busy, Events.onClick (config.deleteMessage message.id) ] [ text (Translations.deleteMessage active.texts) ] ]

                            else
                                []
                           )
                        ++ (if isRecipient && not hidden then
                                [ button [ A.class "text-button", Events.onClick (config.reportMessage messageId) ] [ text (Translations.reportMessage active.texts) ] ]

                            else
                                []
                           )
                        ++ (if isRecipient && not value.read then
                                [ button [ A.class "text-button", Events.onClick (config.markNoticeRead (String.fromInt value.id)) ] [ text (Translations.markRead active.texts) ] ]

                            else
                                []
                           )
                    )
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

        Domain.NotificationModAction _ ->
            a [ A.href (Route.path (Route.Modlog Nothing)) ]
                [ text (Translations.notificationModeration active.texts) ]

        Domain.NotificationPrivateMessage message ->
            a [ A.href (Route.path (Route.Profile (Domain.profileHandle message.creator))) ]
                [ text (Translations.privateMessages active.texts) ]


noticeActor : Domain.NotificationView -> String
noticeActor notice =
    case notice.data of
        Domain.NotificationComment comment ->
            comment.creator.apId

        Domain.NotificationPost post ->
            post.creator.apId

        Domain.NotificationModAction modlog ->
            Maybe.withDefault "" (Maybe.map .apId modlog.moderator)

        Domain.NotificationPrivateMessage message ->
            Domain.acctOf message.creator


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
            Translations.privateMessages texts

        Domain.SubscribedNotification ->
            Translations.notificationOther texts

        Domain.UnknownNotificationKind _ ->
            Translations.notificationOther texts


pageComposer : Config msg -> ViewModel -> Active -> Html msg
pageComposer config model active =
    pageHeading (Translations.createPrivateMessage active.texts)
        (case model.auth of
            Authenticated account ->
                if not account.localUserView.localUser.privateMessagesEnabled then
                    p [ A.class "card field-error", A.attribute "role" "alert" ] [ text (Translations.messageDisabled active.texts) ]

                else
                    div [ A.class "stack" ]
                        [ p [ A.class "muted" ] [ text (Translations.messageInboxHelp active.texts) ]
                        , viewRemote config.retry
                            active.texts
                            model.composer.recipient
                            (\recipient ->
                                form [ Events.onSubmit config.sendMessage, A.class "card form-stack" ]
                                    [ p []
                                        [ strong [] [ text (Translations.messageTo active.texts) ]
                                        , text " "
                                        , a [ A.href (Route.path (Route.Profile (Domain.profileHandle recipient.person))) ]
                                            [ bdi [] [ text (Domain.displayNameOf recipient.person) ] ]
                                        ]
                                    , AuthoringView.view
                                        { id = "private-message-body"
                                        , label = Translations.messageBody active.texts
                                        , helpId = "private-message-help"
                                        , helpText = Translations.messageInboxHelp active.texts
                                        , required = True
                                        , toMsg = config.authoring
                                        }
                                        active
                                        model.composer.authoring
                                    , case model.composer.localProblem of
                                        Just _ ->
                                            p [ A.class "field-error", A.attribute "role" "alert" ] [ text (Translations.messageRequired active.texts) ]

                                        Nothing ->
                                            text ""
                                    , viewFormProblem active.texts model.composer.problem
                                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.composer.sending ]
                                        [ text (Translations.sendMessage active.texts) ]
                                    ]
                            )
                        ]

            _ ->
                loginRequired active.texts
        )
