module Feature.SiteAdmin.View exposing (Config, ViewModel, pageBans, pageModlog, pageOverview, pageReports, pageSettings)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict
import Feature.SiteAdmin.State exposing (Model)
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, form, h2, input, label, li, option, p, section, select, span, text, textarea, time, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Set
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (Formatting, boolText)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)


type alias Config msg =
    { retry : msg
    , upvotesChanged : Bool -> msg
    , downvotesChanged : Bool -> msg
    , saveSettings : msg
    , reportStateChanged : String -> msg
    , reportCommunityChanged : String -> msg
    , applyReportFilter : msg
    , reportNoteChanged : String -> String -> msg
    , confirmResolveReport : String -> String -> msg
    , modlogCommunityChanged : String -> msg
    , applyModlogFilter : msg
    , banActorChanged : String -> msg
    , banReasonChanged : String -> msg
    , banExpiresChanged : String -> msg
    , createBan : msg
    , confirmRemoveBan : msg
    }


type alias ViewModel =
    { admin : Model
    , auth : AuthState
    , formatted : Maybe Formatting
    , url : Url
    }


authorized : AuthState -> Bool
authorized auth =
    case auth of
        Authenticated identity ->
            Domain.isAdmin identity

        _ ->
            False


pageWrapper : ViewModel -> Active -> String -> Html msg -> Html msg
pageWrapper model active title content =
    case model.auth of
        Authenticated identity ->
            if Domain.isAdmin identity then
                pageHeading title
                    (section [ A.class "primary-column" ]
                        [ p [ A.class "muted" ] [ text (Translations.adminCurrentSiteHelp active.texts) ]
                        , adminNav active
                        , content
                        ]
                    )

            else
                pageHeading title (p [ A.class "card field-error", A.attribute "role" "alert" ] [ text (Translations.forbidden active.texts) ])

        _ ->
            pageHeading title (loginRequired active.texts)


adminNav : Active -> Html msg
adminNav active =
    navLinks
        [ ( Route.Admin, Translations.adminOverview active.texts )
        , ( Route.RegistrationApplications, Translations.registrationApplications active.texts )
        , ( Route.AdminTaglines, Translations.taglines active.texts )
        , ( Route.AdminEmoji, Translations.customEmojis active.texts )
        , ( Route.AdminOAuthProviders, Translations.oauthProviders active.texts )
        , ( Route.AdminUsers, Translations.siteUsers active.texts )
        , ( Route.AdminMedia, Translations.siteMedia active.texts )
        , ( Route.AdminConfiguration, Translations.siteConfiguration active.texts )
        , ( Route.AdminFederation, Translations.federationPolicy active.texts )
        , ( Route.AdminSettings, Translations.adminVoteSettings active.texts )
        , ( Route.Reports, Translations.adminReports active.texts )
        , ( Route.Modlog Nothing, Translations.adminModlog active.texts )
        , ( Route.AdminBans, Translations.adminBans active.texts )
        ]


navLinks : List ( Route.Route, String ) -> Html msg
navLinks items =
    div [ A.class "actions wrap" ]
        (List.map
            (\( route, labelText ) ->
                a [ A.class "outlined-button", A.href (Route.path route) ] [ text labelText ]
            )
            items
        )


pageOverview : Config msg -> ViewModel -> Active -> Html msg
pageOverview config model active =
    pageWrapper model
        active
        (Translations.adminTitle active.texts)
        (section [ A.class "card form-stack" ]
            [ h2 [] [ text (Translations.adminOverview active.texts) ]
            , p [] [ text (Translations.adminCurrentSiteHelp active.texts) ]
            , navLinks
                [ ( Route.Communities, Translations.communitiesTitle active.texts )
                , ( Route.AdminSettings, Translations.adminVoteSettings active.texts )
                , ( Route.Reports, Translations.adminReports active.texts )
                , ( Route.Modlog Nothing, Translations.adminModlog active.texts )
                , ( Route.AdminBans, Translations.adminBans active.texts )
                ]
            ]
        )


pageSettings : Config msg -> ViewModel -> Active -> Html msg
pageSettings config model active =
    let
        ready =
            case model.admin.voteSettings of
                Ready _ ->
                    True

                _ ->
                    False
    in
    pageWrapper model
        active
        (Translations.adminVoteSettings active.texts)
        (form [ Events.onSubmit config.saveSettings, A.class "card form-stack" ]
            [ h2 [] [ text (Translations.voteSettingsTitle active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.voteSettingsHelp active.texts) ]
            , label []
                [ input
                    [ A.type_ "checkbox"
                    , A.checked model.admin.upvotesEnabled
                    , A.disabled (model.admin.settingsBusy || not ready)
                    , Events.onCheck config.upvotesChanged
                    ]
                    []
                , text (" " ++ Translations.upvotesEnabled active.texts)
                ]
            , label []
                [ input
                    [ A.type_ "checkbox"
                    , A.checked model.admin.downvotesEnabled
                    , A.disabled (model.admin.settingsBusy || not ready)
                    , Events.onCheck config.downvotesChanged
                    ]
                    []
                , text (" " ++ Translations.downvotesEnabled active.texts)
                ]
            , viewFormProblem active.texts model.admin.settingsProblem
            , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.admin.settingsBusy || not ready) ]
                [ text (Translations.saveChanges active.texts) ]
            ]
        )


pageReports : Config msg -> ViewModel -> Active -> Html msg
pageReports config model active =
    pageWrapper model
        active
        (Translations.reportsTitle active.texts)
        (div [ A.class "stack" ]
            [ form [ Events.onSubmit config.applyReportFilter, A.class "card form-stack" ]
                [ h2 [] [ text (Translations.adminReports active.texts) ]
                , div []
                    [ label [ A.for "report-state" ] [ text (Translations.reportFilterState active.texts) ]
                    , select
                        [ A.id "report-state"
                        , Events.on "change" (Decode.map config.reportStateChanged (Decode.at [ "target", "value" ] Decode.string))
                        ]
                        [ option [ A.value "", A.selected (model.admin.reportState == "") ] [ text (Translations.allStates active.texts) ]
                        , option [ A.value "open", A.selected (model.admin.reportState == "open") ] [ text (Translations.stateOpen active.texts) ]
                        , option [ A.value "resolved", A.selected (model.admin.reportState == "resolved") ] [ text (Translations.stateResolved active.texts) ]
                        , option [ A.value "rejected", A.selected (model.admin.reportState == "rejected") ] [ text (Translations.stateRejected active.texts) ]
                        ]
                    ]
                , div []
                    [ label [ A.for "report-community" ] [ text (Translations.reportFilterCommunity active.texts) ]
                    , input
                        [ A.id "report-community"
                        , A.type_ "text"
                        , A.value model.admin.reportCommunity
                        , Events.onInput config.reportCommunityChanged
                        ]
                        []
                    ]
                , button [ A.type_ "submit", A.class "outlined-button" ] [ text (Translations.filter active.texts) ]
                ]
            , viewRemote config.retry
                active.texts
                model.admin.reports
                (reportsList config model active)
            ]
        )


reportsList : Config msg -> ViewModel -> Active -> Domain.Page Domain.ReportView -> Html msg
reportsList config model active page =
    if List.isEmpty page.items then
        p [ A.class "empty-state" ] [ text (Translations.noReports active.texts) ]

    else
        div [ A.class "stack" ]
            [ ul [ A.class "roster-list" ]
                (List.map
                    (\report ->
                        li [ A.class "card" ]
                            [ p [ A.class "chips" ]
                                [ span [ A.class "chip" ] [ text (reportTargetKind report) ]
                                , span [ A.class "chip" ] [ text (stateLabel active.texts (reportState report)) ]
                                , time [ A.class "chip", A.datetime (reportCreatedAt report), A.attribute "data-commune-time" "" ] [ text (reportCreatedAt report) ]
                                ]
                            , p [ A.class "metadata" ] [ text (Translations.targetId active.texts ++ ": "), text (reportTargetId report) ]
                            , case reportPrivateMessage report of
                                Just content ->
                                    p [ A.dir "auto" ] [ text content ]

                                Nothing ->
                                    text ""
                            , p [ A.dir "auto" ] [ text (reportReason report) ]
                            , if reportState report == "open" then
                                div [ A.class "form-stack" ]
                                    [ label [ A.for ("report-note-" ++ reportId report) ] [ text (Translations.resolutionNote active.texts) ]
                                    , textarea
                                        [ A.id ("report-note-" ++ reportId report)
                                        , A.value (Dict.get (reportId report) model.admin.reportNotes |> Maybe.withDefault "")
                                        , Events.onInput (config.reportNoteChanged (reportId report))
                                        ]
                                        []
                                    , div [ A.class "actions" ]
                                        [ button
                                            [ A.id ("resolve-report-" ++ reportId report)
                                            , A.type_ "button"
                                            , A.class "filled-button"
                                            , A.disabled (Set.member (reportId report) model.admin.reportBusy)
                                            , Events.onClick (config.confirmResolveReport (reportId report) "resolved")
                                            ]
                                            [ text (Translations.resolveReport active.texts) ]
                                        , button
                                            [ A.type_ "button"
                                            , A.class "outlined-button danger-text"
                                            , A.disabled (Set.member (reportId report) model.admin.reportBusy)
                                            , Events.onClick (config.confirmResolveReport (reportId report) "rejected")
                                            ]
                                            [ text (Translations.rejectReport active.texts) ]
                                        ]
                                    ]

                              else
                                p [ A.class "muted" ] [ text (reportResolution report) ]
                            ]
                    )
                    page.items
                )
            , viewPagination active.texts model.url page.prevPage page.nextPage
            ]


pageModlog : Config msg -> ViewModel -> Active -> Html msg
pageModlog config model active =
    pageWrapper model
        active
        (Translations.modlogTitle active.texts)
        (div [ A.class "stack" ]
            [ form [ Events.onSubmit config.applyModlogFilter, A.class "card form-stack" ]
                [ label [ A.for "modlog-community" ] [ text (Translations.reportFilterCommunity active.texts) ]
                , input
                    [ A.id "modlog-community"
                    , A.type_ "text"
                    , A.value model.admin.modlogCommunity
                    , Events.onInput config.modlogCommunityChanged
                    ]
                    []
                , button [ A.type_ "submit", A.class "outlined-button" ] [ text (Translations.filter active.texts) ]
                ]
            , viewRemote config.retry active.texts model.admin.modlog (modlogList model active)
            ]
        )


modlogList : ViewModel -> Active -> Domain.Page Domain.ModlogView -> Html msg
modlogList model active page =
    if List.isEmpty page.items then
        p [ A.class "empty-state" ] [ text (Translations.noModlog active.texts) ]

    else
        div [ A.class "stack" ]
            [ ul [ A.class "roster-list" ]
                (List.map
                    (\entry ->
                        li [ A.class "card" ]
                            [ p [ A.class "chips" ]
                                [ span [ A.class "chip" ] [ text entry.modlog.kind ]
                                , time [ A.class "chip", A.datetime entry.modlog.publishedAt, A.attribute "data-commune-time" "" ] [ text entry.modlog.publishedAt ]
                                ]
                            , p [ A.class "metadata" ]
                                [ text (Translations.actingActor active.texts ++ ": ")
                                , text (Maybe.withDefault "" (Maybe.map .apId entry.moderator))
                                ]
                            , p [ A.class "metadata" ]
                                [ text (Translations.targetKind active.texts ++ ": ")
                                , text (modlogTargetKind entry)
                                , text " · "
                                , text (Translations.targetId active.texts ++ ": ")
                                , text (modlogTargetId entry)
                                ]
                            , if String.isEmpty (Maybe.withDefault "" entry.modlog.reason) then
                                text ""

                              else
                                p [ A.dir "auto" ] [ text (Maybe.withDefault "" entry.modlog.reason) ]
                            ]
                    )
                    page.items
                )
            , viewPagination active.texts model.url page.prevPage page.nextPage
            ]


pageBans : Config msg -> ViewModel -> Active -> Html msg
pageBans config model active =
    pageWrapper model
        active
        (Translations.banTitle active.texts)
        (form [ Events.onSubmit config.createBan, A.class "card form-stack" ]
            [ h2 [] [ text (Translations.banTitle active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.banNoInventory active.texts) ]
            , div []
                [ label [ A.for "ban-actor" ] [ text (Translations.banActor active.texts) ]
                , input
                    [ A.id "ban-actor"
                    , A.type_ "text"
                    , A.value model.admin.banActor
                    , Events.onInput config.banActorChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "ban-reason" ] [ text (Translations.banReason active.texts) ]
                , textarea
                    [ A.id "ban-reason"
                    , A.value model.admin.banReason
                    , Events.onInput config.banReasonChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "ban-expires" ] [ text (Translations.banExpires active.texts) ]
                , input
                    [ A.id "ban-expires"
                    , A.type_ "text"
                    , A.placeholder "2026-11-01T12:00:00Z"
                    , A.value model.admin.banExpires
                    , Events.onInput config.banExpiresChanged
                    ]
                    []
                , p [ A.class "muted" ] [ text (Translations.optional active.texts) ]
                ]
            , case model.admin.banProblem of
                Just problem ->
                    p [ A.class "field-error", A.attribute "role" "alert" ]
                        [ text
                            (if problem.status == 404 then
                                Translations.banNotActive active.texts

                             else
                                Ui.Feedback.problemText active.texts problem
                            )
                        ]

                Nothing ->
                    text ""
            , div [ A.class "actions" ]
                [ button [ A.type_ "submit", A.class "filled-button", A.disabled model.admin.banBusy ]
                    [ text (Translations.createBan active.texts) ]
                , button [ A.id "site-ban-remove", A.type_ "button", A.class "outlined-button danger-text", A.disabled model.admin.banBusy, Events.onClick config.confirmRemoveBan ]
                    [ text (Translations.removeBan active.texts) ]
                ]
            ]
        )


stateLabel : Translations.I18n -> String -> String
stateLabel texts state =
    case state of
        "open" ->
            Translations.stateOpen texts

        "resolved" ->
            Translations.stateResolved texts

        "rejected" ->
            Translations.stateRejected texts

        _ ->
            state


reportId : Domain.ReportView -> String
reportId reportValue =
    String.fromInt
        (case reportValue of
            Domain.PostReportView report _ _ _ _ ->
                report.id

            Domain.CommentReportView report _ _ _ _ _ ->
                report.id

            Domain.CommunityReportView report _ _ _ ->
                report.id

            Domain.PrivateMessageReportView report _ _ _ _ ->
                report.id
        )


reportState : Domain.ReportView -> String
reportState reportValue =
    if
        case reportValue of
            Domain.PostReportView report _ _ _ _ ->
                report.resolved

            Domain.CommentReportView report _ _ _ _ _ ->
                report.resolved

            Domain.CommunityReportView report _ _ _ ->
                report.resolved

            Domain.PrivateMessageReportView report _ _ _ _ ->
                report.resolved
    then
        "resolved"

    else
        "open"


reportReason : Domain.ReportView -> String
reportReason reportValue =
    case reportValue of
        Domain.PostReportView report _ _ _ _ ->
            report.reason

        Domain.CommentReportView report _ _ _ _ _ ->
            report.reason

        Domain.CommunityReportView report _ _ _ ->
            report.reason

        Domain.PrivateMessageReportView report _ _ _ _ ->
            report.reason


reportTargetKind : Domain.ReportView -> String
reportTargetKind reportValue =
    case reportValue of
        Domain.PostReportView _ _ _ _ _ ->
            "post"

        Domain.CommentReportView _ _ _ _ _ _ ->
            "comment"

        Domain.CommunityReportView _ _ _ _ ->
            "community"

        Domain.PrivateMessageReportView _ _ _ _ _ ->
            "message"


reportTargetId : Domain.ReportView -> String
reportTargetId reportValue =
    case reportValue of
        Domain.PostReportView report _ _ _ _ ->
            String.fromInt report.postId

        Domain.CommentReportView report _ _ _ _ _ ->
            String.fromInt report.commentId

        Domain.CommunityReportView report _ _ _ ->
            String.fromInt report.communityId

        Domain.PrivateMessageReportView report _ _ _ _ ->
            String.fromInt report.privateMessageId


reportPrivateMessage : Domain.ReportView -> Maybe String
reportPrivateMessage reportValue =
    case reportValue of
        Domain.PrivateMessageReportView _ message _ sender _ ->
            Just (Domain.displayNameOf sender ++ ": " ++ message.content)

        _ ->
            Nothing


reportCreatedAt : Domain.ReportView -> String
reportCreatedAt reportValue =
    case reportValue of
        Domain.PostReportView report _ _ _ _ ->
            report.publishedAt

        Domain.CommentReportView report _ _ _ _ _ ->
            report.publishedAt

        Domain.CommunityReportView report _ _ _ ->
            report.publishedAt

        Domain.PrivateMessageReportView report _ _ _ _ ->
            report.publishedAt


reportResolution : Domain.ReportView -> String
reportResolution reportValue =
    case reportValue of
        Domain.PostReportView report _ _ _ _ ->
            Maybe.withDefault "" report.conclusion

        Domain.CommentReportView report _ _ _ _ _ ->
            Maybe.withDefault "" report.conclusion

        Domain.CommunityReportView report _ _ _ ->
            Maybe.withDefault "" report.conclusion

        Domain.PrivateMessageReportView report _ _ _ _ ->
            Maybe.withDefault "" report.conclusion


modlogTargetKind : Domain.ModlogView -> String
modlogTargetKind entry =
    case entry.targetPost of
        Just _ ->
            "post"

        Nothing ->
            case entry.targetComment of
                Just _ ->
                    "comment"

                Nothing ->
                    case entry.targetCommunity of
                        Just _ ->
                            "community"

                        Nothing ->
                            case entry.targetPerson of
                                Just _ ->
                                    "person"

                                Nothing ->
                                    case entry.targetInstance of
                                        Just _ ->
                                            "instance"

                                        Nothing ->
                                            ""


modlogTargetId : Domain.ModlogView -> String
modlogTargetId entry =
    case entry.targetPost of
        Just value ->
            String.fromInt value.id

        Nothing ->
            case entry.targetComment of
                Just value ->
                    String.fromInt value.id

                Nothing ->
                    case entry.targetCommunity of
                        Just value ->
                            String.fromInt value.id

                        Nothing ->
                            case entry.targetPerson of
                                Just value ->
                                    value.apId

                                Nothing ->
                                    case entry.targetInstance of
                                        Just value ->
                                            value.domain

                                        Nothing ->
                                            ""
