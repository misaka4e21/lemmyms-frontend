module Feature.CommunityManage.View exposing (Config, pageManage)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict
import Feature.CommunityManage.State exposing (..)
import File exposing (File)
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, div, form, h2, img, input, label, li, option, p, section, select, span, text, textarea, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Ui.CommunityPolicy exposing (policyFields)
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (modeLabel, policyLabel)
import Ui.Layout exposing (pageHeading)


type alias Config msg =
    { retry : msg
    , manageActorChanged : String -> msg
    , managePostChanged : String -> msg
    , manageContextChanged : String -> msg
    , manageReadChanged : String -> msg
    , managePostPolicyChanged : String -> msg
    , manageFollowPolicyChanged : String -> msg
    , manageFieldChanged : String -> String -> msg
    , manageApplyPolicy : msg
    , manageAddMember : msg
    , manageRemoveMember : String -> msg
    , manageAddManager : msg
    , manageTransferCommunity : msg
    , manageRemoveManager : String -> msg
    , managePreviousMembers : msg
    , manageNextMembers : msg
    , managePreviousManagers : msg
    , manageNextManagers : msg
    , managePreviousFollowRequests : msg
    , manageNextFollowRequests : msg
    , managePreviousReports : msg
    , manageNextReports : msg
    , managePreviousModlog : msg
    , manageNextModlog : msg
    , managePostAction : String -> ManagePostAction -> msg
    , manageFollowDecision : String -> String -> msg
    , manageReportNoteChanged : String -> String -> msg
    , manageConfirmResolveReport : String -> String -> msg
    , manageBanActorChanged : String -> msg
    , manageBanReasonChanged : String -> msg
    , manageBanExpiresChanged : String -> msg
    , manageCreateBan : msg
    , manageConfirmRemoveBan : msg
    , manageTagNameChanged : String -> msg
    , manageTagDisplayNameChanged : String -> msg
    , manageTagColorChanged : String -> msg
    , manageCreateTag : msg
    , manageDeleteTag : Int -> msg
    , manageIconSelected : Maybe File -> msg
    , manageBannerSelected : Maybe File -> msg
    }


type alias ViewModel =
    { auth : AuthState, manage : Maybe ManageState }


pageManage : Config msg -> ViewModel -> Active -> String -> Html msg
pageManage config model active communityIdValue =
    pageHeading (Translations.manageTitle active.texts)
        (case ( model.auth, model.manage ) of
            ( Authenticated _, Just manage ) ->
                section [ A.class "primary-column" ]
                    [ viewRemote config.retry active.texts manage.community (communitySection active)
                    , case model.auth of
                        Authenticated identity ->
                            if Domain.isAdmin identity then
                                a [ A.class "outlined-button", A.href (Route.path Route.Admin) ]
                                    [ text (Translations.adminTitle active.texts) ]

                            else
                                text ""

                        _ ->
                            text ""
                    , if canManageCommunity manage then
                        managePolicy config active manage

                      else
                        text ""
                    , if canManageCommunity manage then
                        manageImages config active manage

                      else
                        text ""
                    , if canManageCommunity manage then
                        manageTags config active manage

                      else
                        text ""
                    , manageRosters config active manage
                    , manageFollowRequests config active manage
                    , manageReports config active manage
                    , manageModlog config active manage
                    , manageBans config active manage
                    , managePostActions config model active manage
                    ]

            _ ->
                loginRequired active.texts
        )


communitySection : Active -> Domain.CommunityView -> Html msg
communitySection active community =
    section [ A.class "card" ]
        [ h2 [] [ text (Maybe.withDefault community.community.name community.community.title) ]
        , p [ A.class "metadata" ]
            [ text
                (Translations.policySummary
                    { read = policyLabel active.texts (visibilityText community.community.visibility)
                    , post =
                        policyLabel active.texts
                            (if community.community.postingRestrictedToMods then
                                "managers"

                             else
                                "eligible_users"
                            )
                    }
                    active.texts
                )
            ]
        , p [ A.class "chips" ] [ span [ A.class "chip" ] [ text (modeLabel active.texts (visibilityText community.community.visibility)) ] ]
        ]


manageImages : Config msg -> Active -> ManageState -> Html msg
manageImages config active manage =
    case manage.community of
        Ready community ->
            section [ A.class "card form-stack" ]
                [ h2 [] [ text (Translations.communityDetail active.texts) ]
                , case community.community.icon of
                    Just icon ->
                        img [ A.class "community-icon", A.src icon, A.alt "", A.attribute "referrerpolicy" "no-referrer" ] []

                    Nothing ->
                        text ""
                , div []
                    [ label [ A.for "manage-icon" ] [ text (Translations.uploadIcon active.texts) ]
                    , input
                        [ A.id "manage-icon"
                        , A.type_ "file"
                        , A.attribute "accept" "image/*"
                        , Events.on "change" (Json.Decode.maybe (Json.Decode.at [ "target", "files", "0" ] File.decoder) |> Json.Decode.map config.manageIconSelected)
                        ]
                        []
                    ]
                , case community.community.banner of
                    Just banner ->
                        img [ A.class "community-banner", A.src banner, A.alt "", A.attribute "referrerpolicy" "no-referrer" ] []

                    Nothing ->
                        text ""
                , div []
                    [ label [ A.for "manage-banner" ] [ text (Translations.uploadBanner active.texts) ]
                    , input
                        [ A.id "manage-banner"
                        , A.type_ "file"
                        , A.attribute "accept" "image/*"
                        , Events.on "change" (Json.Decode.maybe (Json.Decode.at [ "target", "files", "0" ] File.decoder) |> Json.Decode.map config.manageBannerSelected)
                        ]
                        []
                    ]
                , if manage.iconUploading || manage.bannerUploading then
                    p [ A.class "muted", A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]

                  else
                    text ""
                ]

        _ ->
            text ""


manageTags : Config msg -> Active -> ManageState -> Html msg
manageTags config active manage =
    case manage.community of
        Ready community ->
            section [ A.class "card form-stack" ]
                [ h2 [] [ text (Translations.tags active.texts) ]
                , if List.isEmpty community.tags then
                    p [ A.class "muted" ] [ text (Translations.noTags active.texts) ]

                  else
                    ul [ A.class "roster-list" ]
                        (List.map
                            (\tag ->
                                li []
                                    [ span [ A.class "chip" ] [ text (Maybe.withDefault tag.name tag.displayName) ]
                                    , button
                                        [ A.type_ "button"
                                        , A.class "text-button danger-text"
                                        , Events.onClick (config.manageDeleteTag tag.id)
                                        ]
                                        [ text (Translations.deleteTag active.texts) ]
                                    ]
                            )
                            community.tags
                        )
                , div []
                    [ label [ A.for "manage-tag-name" ] [ text (Translations.tagName active.texts) ]
                    , input
                        [ A.id "manage-tag-name"
                        , A.type_ "text"
                        , A.value manage.tagName
                        , Events.onInput config.manageTagNameChanged
                        ]
                        []
                    ]
                , div []
                    [ label [ A.for "manage-tag-display-name" ] [ text (Translations.tagDisplayName active.texts) ]
                    , input
                        [ A.id "manage-tag-display-name"
                        , A.type_ "text"
                        , A.value manage.tagDisplayName
                        , Events.onInput config.manageTagDisplayNameChanged
                        ]
                        []
                    ]
                , div []
                    [ label [ A.for "manage-tag-color" ] [ text (Translations.colorLabel active.texts) ]
                    , select
                        [ A.id "manage-tag-color"
                        , Events.on "change" (Json.Decode.map config.manageTagColorChanged (Json.Decode.at [ "target", "value" ] Json.Decode.string))
                        ]
                        (List.map
                            (\color ->
                                option [ A.value color, A.selected (color == manage.tagColor) ] [ text color ]
                            )
                            [ "color_01", "color_02", "color_03", "color_04", "color_05", "color_06", "color_07", "color_08", "color_09", "color_10" ]
                        )
                    ]
                , button
                    [ A.type_ "button"
                    , A.class "filled-button"
                    , A.disabled manage.tagBusy
                    , Events.onClick config.manageCreateTag
                    ]
                    [ text (Translations.addTag active.texts) ]
                ]

        _ ->
            text ""


managePolicy : Config msg -> Active -> ManageState -> Html msg
managePolicy config active manage =
    form [ Events.onSubmit config.manageApplyPolicy, A.class "card form-stack" ]
        [ h2 [] [ text (Translations.readPolicy active.texts) ]
        , manageText "manage-title" (Translations.communityTitle active.texts) manage.title "title" config
        , manageText "manage-sidebar" (Translations.communitySidebar active.texts) manage.sidebar "sidebar" config
        , manageText "manage-summary" (Translations.communitySummary active.texts) manage.summary "summary" config
        , manageCheckbox "manage-nsfw" (Translations.communityNsfw active.texts) manage.nsfw "nsfw" config
        , manageSelect "manage-visibility"
            (Translations.communityVisibility active.texts)
            manage.visibility
            "visibility"
            [ ( "public", Translations.visibilityPublic active.texts )
            , ( "unlisted", Translations.visibilityUnlisted active.texts )
            , ( "local_only_public", Translations.visibilityLocalPublic active.texts )
            , ( "local_only_private", Translations.visibilityLocalPrivate active.texts )
            , ( "private", Translations.visibilityPrivate active.texts )
            ]
            config
        , manageCheckbox "manage-posting-restricted" (Translations.postingRestricted active.texts) manage.postingRestricted "postingRestricted" config
        , manageText "manage-languages" (Translations.discussionLanguages active.texts) manage.discussionLanguages "discussionLanguages" config
        , manageVote "manage-post-upvotes" (Translations.postUpvotes active.texts) manage.postUpvotes "postUpvotes" config active
        , manageVote "manage-post-downvotes" (Translations.postDownvotes active.texts) manage.postDownvotes "postDownvotes" config active
        , manageVote "manage-comment-upvotes" (Translations.commentUpvotes active.texts) manage.commentUpvotes "commentUpvotes" config active
        , manageVote "manage-comment-downvotes" (Translations.commentDownvotes active.texts) manage.commentDownvotes "commentDownvotes" config active
        , button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.saveChanges active.texts) ]
        ]


manageRosters : Config msg -> Active -> ManageState -> Html msg
manageRosters config active manage =
    let
        canManagers =
            canManageManagers manage
    in
    section [ A.class "stack" ]
        [ if canManagers then
            div [ A.class "card form-stack" ]
                [ label [ A.for "manage-actor" ] [ text (Translations.personId active.texts) ]
                , input [ A.id "manage-actor", A.type_ "text", A.value manage.actor, Events.onInput config.manageActorChanged ]
                    []
                , div [ A.class "actions" ]
                    [ if canManagers then
                        button [ A.type_ "button", A.class "outlined-button", Events.onClick config.manageAddManager ]
                            [ text (Translations.addManager active.texts) ]

                      else
                        text ""
                    , if canManagers then
                        button [ A.type_ "button", A.class "outlined-button", Events.onClick config.manageTransferCommunity ]
                            [ text (Translations.transferCommunity active.texts) ]

                      else
                        text ""
                    ]
                ]

          else
            text ""
        , rosterPanel config active (Translations.managerRoster active.texts) manage.managers False canManagers manage.managerOffset config.managePreviousManagers config.manageNextManagers
        ]


rosterPanel :
    Config msg
    -> Active
    -> String
    -> Remote (Domain.Page Domain.CommunityModeratorView)
    -> Bool
    -> Bool
    -> Int
    -> msg
    -> msg
    -> Html msg
rosterPanel config active title remote members canRemove offset onPrevious onNext =
    section [ A.class "card" ]
        [ h2 [] [ text title ]
        , viewRemote config.retry
            active.texts
            remote
            (\page ->
                if List.isEmpty page.items then
                    p [ A.class "muted" ] [ text (Translations.noRosterEntries active.texts) ]

                else
                    ul [ A.class "roster-list" ]
                        (List.map
                            (\entry ->
                                li []
                                    [ bdi [] [ text entry.moderator.apId ]
                                    , span [ A.class "chips" ]
                                        [ if canRemove then
                                            button
                                                [ A.type_ "button"
                                                , A.class "text-button danger-text"
                                                , Events.onClick
                                                    (if members then
                                                        config.manageRemoveMember entry.moderator.apId

                                                     else
                                                        config.manageRemoveManager entry.moderator.apId
                                                    )
                                                ]
                                                [ text
                                                    (if members then
                                                        Translations.removeMember active.texts

                                                     else
                                                        Translations.removeManager active.texts
                                                    )
                                                ]

                                          else
                                            text ""
                                        ]
                                    ]
                            )
                            page.items
                        )
                        |> (\rows ->
                                div [ A.class "stack" ]
                                    [ rows
                                    , div [ A.class "pagination" ]
                                        [ button [ A.type_ "button", A.class "outlined-button", A.disabled (offset <= 0), Events.onClick onPrevious ]
                                            [ text (Translations.previousPage active.texts) ]
                                        , if page.nextPage /= Nothing then
                                            button [ A.type_ "button", A.class "outlined-button", Events.onClick onNext ]
                                                [ text (Translations.nextPage active.texts) ]

                                          else
                                            text ""
                                        ]
                                    ]
                           )
            )
        ]


manageFollowRequests : Config msg -> Active -> ManageState -> Html msg
manageFollowRequests config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        section [ A.class "card" ]
            [ h2 [] [ text (Translations.followRequests active.texts) ]
            , viewRemote config.retry
                active.texts
                manage.followRequests
                (\page ->
                    if List.isEmpty page.items then
                        p [ A.class "muted" ] [ text (Translations.noFollowRequests active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "roster-list" ]
                                (List.map
                                    (\request ->
                                        li []
                                            [ bdi [] [ text request.person.apId ]
                                            , span [ A.class "actions" ]
                                                [ button
                                                    [ A.type_ "button"
                                                    , A.class "text-button"
                                                    , Events.onClick (config.manageFollowDecision request.person.apId "accepted")
                                                    ]
                                                    [ text (Translations.accept active.texts) ]
                                                , button
                                                    [ A.type_ "button"
                                                    , A.class "text-button danger-text"
                                                    , Events.onClick (config.manageFollowDecision request.person.apId "rejected")
                                                    ]
                                                    [ text (Translations.reject active.texts) ]
                                                ]
                                            ]
                                    )
                                    page.items
                                )
                            , pager active page manage.followRequestOffset config.managePreviousFollowRequests config.manageNextFollowRequests
                            ]
                )
            ]


manageReports : Config msg -> Active -> ManageState -> Html msg
manageReports config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        section [ A.class "card" ]
            [ h2 [] [ text (Translations.reportsTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                manage.reports
                (\page ->
                    if List.isEmpty page.items then
                        p [ A.class "muted" ] [ text (Translations.noReports active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "roster-list" ]
                                (List.map
                                    (\report ->
                                        li []
                                            [ p [ A.class "chips" ]
                                                [ span [ A.class "chip" ] [ text (reportTargetKind report) ]
                                                , span [ A.class "chip" ] [ text (reportState report) ]
                                                ]
                                            , p [ A.dir "auto" ] [ text (reportReason report) ]
                                            , if reportState report == "open" then
                                                div [ A.class "form-stack" ]
                                                    [ label [ A.for ("community-report-note-" ++ reportId report) ] [ text (Translations.resolutionNote active.texts) ]
                                                    , textarea
                                                        [ A.id ("community-report-note-" ++ reportId report)
                                                        , A.value (Dict.get (reportId report) manage.reportNotes |> Maybe.withDefault "")
                                                        , Events.onInput (config.manageReportNoteChanged (reportId report))
                                                        ]
                                                        []
                                                    , div [ A.class "actions" ]
                                                        [ button
                                                            [ A.id ("resolve-report-" ++ reportId report)
                                                            , A.type_ "button"
                                                            , A.class "filled-button"
                                                            , Events.onClick (config.manageConfirmResolveReport (reportId report) "resolved")
                                                            ]
                                                            [ text (Translations.resolveReport active.texts) ]
                                                        , button
                                                            [ A.type_ "button"
                                                            , A.class "outlined-button danger-text"
                                                            , Events.onClick (config.manageConfirmResolveReport (reportId report) "rejected")
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
                            , pager active page manage.reportOffset config.managePreviousReports config.manageNextReports
                            ]
                )
            ]


manageModlog : Config msg -> Active -> ManageState -> Html msg
manageModlog config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        section [ A.class "card" ]
            [ h2 [] [ text (Translations.modlogTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                manage.modlog
                (\page ->
                    if List.isEmpty page.items then
                        p [ A.class "muted" ] [ text (Translations.noModlog active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "roster-list" ]
                                (List.map
                                    (\entry ->
                                        li []
                                            [ p [ A.class "chips" ]
                                                [ span [ A.class "chip" ] [ text entry.modlog.kind ]
                                                ]
                                            , p [ A.class "metadata" ] [ bdi [] [ text (Maybe.withDefault "" (Maybe.map .apId entry.moderator)) ] ]
                                            , p [ A.class "metadata" ] [ text (modlogTarget entry) ]
                                            , if String.isEmpty (Maybe.withDefault "" entry.modlog.reason) then
                                                text ""

                                              else
                                                p [ A.dir "auto" ] [ text (Maybe.withDefault "" entry.modlog.reason) ]
                                            ]
                                    )
                                    page.items
                                )
                            , pager active page manage.modlogOffset config.managePreviousModlog config.manageNextModlog
                            ]
                )
            ]


pager : Active -> Domain.Page a -> Int -> msg -> msg -> Html msg
pager active page offset onPrevious onNext =
    div [ A.class "pagination" ]
        [ button [ A.type_ "button", A.class "outlined-button", A.disabled (page.prevPage == Nothing), Events.onClick onPrevious ]
            [ text (Translations.previousPage active.texts) ]
        , if page.nextPage /= Nothing then
            button [ A.type_ "button", A.class "outlined-button", Events.onClick onNext ]
                [ text (Translations.nextPage active.texts) ]

          else
            text ""
        ]


manageBans : Config msg -> Active -> ManageState -> Html msg
manageBans config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        form [ Events.onSubmit config.manageCreateBan, A.class "card form-stack" ]
            [ h2 [] [ text (Translations.communityBanTitle active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.communityBanHelp active.texts) ]
            , div []
                [ label [ A.for "community-ban-actor" ] [ text (Translations.banActor active.texts) ]
                , input
                    [ A.id "community-ban-actor"
                    , A.type_ "text"
                    , A.value manage.banActor
                    , Events.onInput config.manageBanActorChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "community-ban-reason" ] [ text (Translations.banReason active.texts) ]
                , textarea
                    [ A.id "community-ban-reason"
                    , A.value manage.banReason
                    , Events.onInput config.manageBanReasonChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "community-ban-expires" ] [ text (Translations.banExpires active.texts) ]
                , input
                    [ A.id "community-ban-expires"
                    , A.type_ "text"
                    , A.placeholder "2026-11-01T12:00:00Z"
                    , A.value manage.banExpires
                    , Events.onInput config.manageBanExpiresChanged
                    ]
                    []
                ]
            , viewFormProblem active.texts manage.banProblem
            , div [ A.class "actions" ]
                [ button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.createBan active.texts) ]
                , button [ A.id "community-ban-remove", A.type_ "button", A.class "outlined-button danger-text", Events.onClick config.manageConfirmRemoveBan ]
                    [ text (Translations.removeBan active.texts) ]
                ]
            ]


managePostActions : Config msg -> ViewModel -> Active -> ManageState -> Html msg
managePostActions config model active manage =
    let
        moderate =
            canManageCommunity manage
    in
    section [ A.class "card form-stack" ]
        [ h2 [] [ text (Translations.postId active.texts) ]
        , label [ A.for "manage-post-id" ] [ text (Translations.postId active.texts) ]
        , input [ A.id "manage-post-id", A.type_ "text", A.value manage.postId, Events.onInput config.managePostChanged ] []
        , div [ A.class "actions wrap" ]
            [ if moderate then
                managePostButton config active "remove" RemoveCommunityPost manage.postId

              else
                text ""
            , if moderate then
                managePostButton config active "restore" RestoreCommunityPost manage.postId

              else
                text ""
            ]
        , viewFormProblem active.texts manage.problem
        ]


managePostButton : Config msg -> Active -> String -> ManagePostAction -> String -> Html msg
managePostButton config active _ action id =
    button
        [ A.type_ "button"
        , A.class "outlined-button"
        , A.disabled (String.isEmpty (String.trim id))
        , Events.onClick (config.managePostAction id action)
        ]
        [ text (manageActionLabel active.texts action) ]


manageActionLabel : Translations.I18n -> ManagePostAction -> String
manageActionLabel texts action =
    case action of
        RemoveCommunityPost ->
            Translations.removePostFromCommunity texts

        RestoreCommunityPost ->
            Translations.restorePostToCommunity texts

        HideSitePost ->
            Translations.hidePost texts

        UnhideSitePost ->
            Translations.unhidePost texts

        ImportSitePost ->
            Translations.importPost texts

        AcceptSubmission ->
            Translations.acceptSubmission texts

        RejectSubmission ->
            Translations.rejectSubmission texts

        BackfillDiscussion ->
            Translations.backfillContext texts


canManageCommunity : ManageState -> Bool
canManageCommunity manage =
    case manage.community of
        Ready community ->
            community.canMod

        _ ->
            False


canManageMembers : ManageState -> Bool
canManageMembers manage =
    case manage.community of
        Ready community ->
            community.canMod

        _ ->
            False


canManageManagers : ManageState -> Bool
canManageManagers manage =
    case manage.community of
        Ready community ->
            community.canMod

        _ ->
            False


visibilityText : Domain.CommunityVisibility -> String
visibilityText visibility =
    case visibility of
        Domain.PublicCommunity ->
            "public"

        Domain.UnlistedCommunity ->
            "unlisted"

        Domain.LocalOnlyPublicCommunity ->
            "local_only_public"

        Domain.LocalOnlyPrivateCommunity ->
            "local_only_private"

        Domain.PrivateCommunity ->
            "private"

        Domain.UnknownVisibility value ->
            value


manageText : String -> String -> String -> String -> Config msg -> Html msg
manageText identifier labelText value field config =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , input [ A.id identifier, A.type_ "text", A.value value, Events.onInput (config.manageFieldChanged field) ] []
        ]


manageCheckbox : String -> String -> Bool -> String -> Config msg -> Html msg
manageCheckbox identifier labelText checked field config =
    label [ A.for identifier ]
        [ input
            [ A.id identifier
            , A.type_ "checkbox"
            , A.checked checked
            , Events.onCheck (config.manageFieldChanged field << boolText)
            ]
            []
        , text (" " ++ labelText)
        ]


manageSelect : String -> String -> String -> String -> List ( String, String ) -> Config msg -> Html msg
manageSelect identifier labelText value field options config =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , select
            [ A.id identifier
            , Events.on "change" (Json.Decode.map (config.manageFieldChanged field) (Json.Decode.at [ "target", "value" ] Json.Decode.string))
            ]
            (List.map (\( optionValue, optionLabel ) -> option [ A.value optionValue, A.selected (value == optionValue) ] [ text optionLabel ]) options)
        ]


manageVote : String -> String -> String -> String -> Config msg -> Active -> Html msg
manageVote identifier labelText value field config active =
    manageSelect identifier
        labelText
        value
        field
        [ ( "all", Translations.voteAll active.texts )
        , ( "local", Translations.voteLocal active.texts )
        , ( "subscribed", Translations.voteSubscribed active.texts )
        , ( "disable", Translations.voteDisabled active.texts )
        ]
        config


boolText : Bool -> String
boolText value =
    if value then
        "true"

    else
        "false"


modlogTarget : Domain.ModlogView -> String
modlogTarget entry =
    case entry.targetPost of
        Just postValue ->
            "post: " ++ String.fromInt postValue.id

        Nothing ->
            case entry.targetComment of
                Just commentValue ->
                    "comment: " ++ String.fromInt commentValue.id

                Nothing ->
                    case entry.targetCommunity of
                        Just communityValue ->
                            "community: " ++ String.fromInt communityValue.id

                        Nothing ->
                            case entry.targetPerson of
                                Just personValue ->
                                    "person: " ++ personValue.apId

                                Nothing ->
                                    case entry.targetInstance of
                                        Just instanceValue ->
                                            "instance: " ++ instanceValue.domain

                                        Nothing ->
                                            ""


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

            Domain.PrivateMessageReportView id _ _ _ _ _ _ ->
                id
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

            Domain.PrivateMessageReportView _ _ resolved _ _ _ _ ->
                resolved
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

        Domain.PrivateMessageReportView _ reason _ _ _ _ _ ->
            reason


reportTargetKind : Domain.ReportView -> String
reportTargetKind reportValue =
    case reportValue of
        Domain.PostReportView _ _ _ _ _ ->
            "post"

        Domain.CommentReportView _ _ _ _ _ _ ->
            "comment"

        Domain.CommunityReportView _ _ _ _ ->
            "community"

        Domain.PrivateMessageReportView _ _ _ _ _ _ _ ->
            "message"


reportResolution : Domain.ReportView -> String
reportResolution reportValue =
    case reportValue of
        Domain.PostReportView report _ _ _ _ ->
            Maybe.withDefault "" report.conclusion

        Domain.CommentReportView report _ _ _ _ _ ->
            Maybe.withDefault "" report.conclusion

        Domain.CommunityReportView report _ _ _ ->
            Maybe.withDefault "" report.conclusion

        Domain.PrivateMessageReportView _ _ _ conclusion _ _ _ ->
            Maybe.withDefault "" conclusion
