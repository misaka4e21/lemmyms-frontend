module Feature.CommunityManage.Update exposing (Action(..), LoadKind(..), Msg(..), Outcome, load, update)

import Api
import App.Feedback exposing (Flash(..))
import Dict
import Feature.CommunityManage.State exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Url


type Msg
    = Loaded LoadKind Api.Response
    | ActionDone Action Api.Response
    | ManageActorChanged String
    | ManagePostChanged String
    | ManageContextChanged String
    | ManageReadChanged String
    | ManagePostPolicyChanged String
    | ManageFollowPolicyChanged String
    | ManageFieldChanged String String
    | ManageApplyPolicy
    | ManageAddMember
    | ManageRemoveMember String
    | ManageAddManager
    | ManageTransferCommunity
    | ManageRemoveManager String
    | ManagePreviousMembers
    | ManageNextMembers
    | ManagePreviousManagers
    | ManageNextManagers
    | ManagePreviousFollowRequests
    | ManageNextFollowRequests
    | ManagePreviousReports
    | ManageNextReports
    | ManagePreviousModlog
    | ManageNextModlog
    | ManagePostAction String ManagePostAction
    | ManageFollowDecision String String
    | ManageReportNoteChanged String String
    | ManageResolveReport String String
    | ManageBanActorChanged String
    | ManageBanReasonChanged String
    | ManageBanExpiresChanged String
    | ManageCreateBan
    | ManageRemoveBan


type LoadKind
    = LoadManageCommunity String
    | LoadMembers String Int
    | LoadManagers String Int
    | LoadFollowRequests String Int
    | LoadReports String
    | LoadModlog String Int


type Action
    = ManageAction String
    | ManagePostActionDone String ManagePostAction


type alias Context =
    { csrf : String, route : Route.Route, viewerId : Maybe Int }


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { manage : Maybe ManageState, busy : Set String, flash : Flash, sessionProblem : Maybe Api.Problem }


update : Context -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update context message state =
    let
        ( next, command ) =
            updateWorking context message { manage = state.manage, busy = state.busy, flash = NoFlash, sessionProblem = Nothing }
    in
    ( { manage = next.manage, busy = next.busy }, command, { flash = next.flash, sessionProblem = next.sessionProblem } )


load : String -> ManageState -> Model -> ( Model, Cmd Msg )
load id manage state =
    ( { state | manage = Just manage }
    , Cmd.batch
        [ Api.get ("/community?id=" ++ urlEncode id) (Loaded (LoadManageCommunity id))
        , Api.get ("/community/pending_follows/list?community_id=" ++ urlEncode id ++ "&limit=20") (Loaded (LoadFollowRequests id manage.followRequestOffset))
        , Api.get ("/report/list?unresolved_only=true&community_id=" ++ urlEncode id ++ "&limit=20") (Loaded (LoadReports id))
        , Api.get ("/modlog?community_id=" ++ urlEncode id ++ "&limit=20") (Loaded (LoadModlog id manage.modlogOffset))
        ]
    )


authProblem : Working -> Api.Problem -> Working
authProblem model problem =
    if problem.status == 401 then
        { model | sessionProblem = Just problem }

    else
        model


urlEncode : String -> String
urlEncode =
    Url.percentEncode


updateWorking : Context -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking context message model =
    case message of
        ManageActorChanged value ->
            setManage model (\manage -> { manage | actor = value, problem = Nothing }) Cmd.none

        ManagePostChanged value ->
            setManage model (\manage -> { manage | postId = value, problem = Nothing }) Cmd.none

        ManageContextChanged value ->
            setManage model (\manage -> { manage | contextId = value, problem = Nothing }) Cmd.none

        ManageReadChanged value ->
            setManage model
                (\manage ->
                    { manage
                        | readPolicy = value
                        , postPolicy =
                            if value == "members" && manage.postPolicy == "eligible_users" then
                                "members"

                            else
                                manage.postPolicy
                    }
                )
                Cmd.none

        ManagePostPolicyChanged value ->
            setManage model
                (\manage ->
                    { manage
                        | postPolicy = value
                        , readPolicy =
                            if value == "eligible_users" && manage.readPolicy == "members" then
                                "eligible_users"

                            else
                                manage.readPolicy
                    }
                )
                Cmd.none

        ManageFollowPolicyChanged value ->
            setManage model (\manage -> { manage | followPolicy = value, problem = Nothing }) Cmd.none

        ManageFieldChanged field value ->
            setManage model (\manage -> setField field value manage) Cmd.none

        ManageApplyPolicy ->
            case model.manage of
                Just manage ->
                    manageRequest context
                        model
                        "policy"
                        "PUT"
                        "/community"
                        (Encode.encode 0
                            (Encode.object
                                [ ( "community_id", Encode.int (String.toInt (communityId context.route) |> Maybe.withDefault 0) )
                                , ( "title", Encode.string manage.title )
                                , ( "sidebar", Encode.string manage.sidebar )
                                , ( "summary", Encode.string manage.summary )
                                , ( "nsfw", Encode.bool manage.nsfw )
                                , ( "visibility", Encode.string manage.visibility )
                                , ( "posting_restricted_to_mods", Encode.bool manage.postingRestricted )
                                , ( "discussion_languages", Encode.list Encode.int (parseIds manage.discussionLanguages) )
                                , ( "post_upvotes", Encode.string manage.postUpvotes )
                                , ( "post_downvotes", Encode.string manage.postDownvotes )
                                , ( "comment_upvotes", Encode.string manage.commentUpvotes )
                                , ( "comment_downvotes", Encode.string manage.commentDownvotes )
                                ]
                            )
                        )

                Nothing ->
                    ( model, Cmd.none )

        ManageAddMember ->
            manageActorRequest context model "add-member" "POST" "members"

        ManageRemoveMember actor ->
            manageActorRequestFor context model "remove-member" "DELETE" "members" actor

        ManageAddManager ->
            manageActorRequest context model "add-manager" "POST" "managers"

        ManageTransferCommunity ->
            case model.manage of
                Just manage ->
                    if String.toInt manage.actor == context.viewerId then
                        ( model, Cmd.none )

                    else
                        manageRequest context
                            model
                            "transfer"
                            "POST"
                            "/community/transfer"
                            (Encode.encode 0
                                (Encode.object
                                    [ ( "community_id", Encode.int (String.toInt (communityId context.route) |> Maybe.withDefault 0) )
                                    , ( "person_id", Encode.int (String.toInt manage.actor |> Maybe.withDefault 0) )
                                    ]
                                )
                            )

                Nothing ->
                    ( model, Cmd.none )

        ManageRemoveManager actor ->
            manageActorRequestFor context model "remove-manager" "DELETE" "managers" actor

        ManagePreviousMembers ->
            managePage context model True -20

        ManageNextMembers ->
            managePage context model True 20

        ManagePreviousManagers ->
            managePage context model False -20

        ManageNextManagers ->
            managePage context model False 20

        ManagePreviousFollowRequests ->
            manageSectionPage context model "follow" -20

        ManageNextFollowRequests ->
            manageSectionPage context model "follow" 20

        ManagePreviousReports ->
            manageSectionPage context model "reports" -20

        ManageNextReports ->
            manageSectionPage context model "reports" 20

        ManagePreviousModlog ->
            manageSectionPage context model "modlog" -20

        ManageNextModlog ->
            manageSectionPage context model "modlog" 20

        ManagePostAction id action ->
            managePostRequest context model id action

        ManageFollowDecision actor stateValue ->
            let
                personId =
                    model.manage
                        |> Maybe.map (followerIdFor actor)
                        |> Maybe.withDefault 0
            in
            manageRequest context
                model
                ("follow-" ++ actor ++ "-" ++ stateValue)
                "POST"
                "/community/pending_follows/approve"
                (Encode.encode 0
                    (Encode.object
                        [ ( "community_id", Encode.int (String.toInt (communityId context.route) |> Maybe.withDefault 0) )
                        , ( "follower_id", Encode.int personId )
                        , ( "approve", Encode.bool (stateValue == "accepted") )
                        ]
                    )
                )

        ManageReportNoteChanged id value ->
            setManage model
                (\manage -> { manage | reportNotes = Dict.insert id value manage.reportNotes })
                Cmd.none

        ManageResolveReport id resolution ->
            manageRequest context
                model
                ("resolve-report-" ++ id ++ "-" ++ resolution)
                "PUT"
                (resolvePath id model)
                (Encode.encode 0
                    (Encode.object
                        [ ( "report_id", Encode.int (String.toInt id |> Maybe.withDefault 0) )
                        , ( "resolved", Encode.bool (resolution == "resolved") )
                        , ( "conclusion"
                          , Encode.string
                                (model.manage
                                    |> Maybe.map (\manage -> Dict.get id manage.reportNotes |> Maybe.withDefault "")
                                    |> Maybe.withDefault ""
                                )
                          )
                        ]
                    )
                )

        ManageBanActorChanged value ->
            setManage model (\manage -> { manage | banActor = value, banProblem = Nothing }) Cmd.none

        ManageBanReasonChanged value ->
            setManage model (\manage -> { manage | banReason = value, banProblem = Nothing }) Cmd.none

        ManageBanExpiresChanged value ->
            setManage model (\manage -> { manage | banExpires = value, banProblem = Nothing }) Cmd.none

        ManageCreateBan ->
            communityBanRequest context model "POST"

        ManageRemoveBan ->
            communityBanRequest context model "DELETE"

        ActionDone (ManageAction key) response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        changed =
                            { model | flash = FlashSaved }
                    in
                    case context.route of
                        Route.Manage id ->
                            loadManageState 0
                                id
                                (Maybe.withDefault emptyManage (model.manage |> Maybe.map (\manage -> { manage | problem = Nothing })))
                                changed

                        _ ->
                            ( changed, Cmd.none )

                Err problem ->
                    let
                        base =
                            authProblem model problem
                    in
                    ( { base
                        | flash = FlashProblem problem
                        , manage = model.manage |> Maybe.map (\manage -> { manage | problem = Just problem })
                      }
                    , Cmd.none
                    )

        ActionDone (ManagePostActionDone key managedAction) response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        changed =
                            { model | flash = FlashSaved }
                    in
                    case context.route of
                        Route.Manage id ->
                            loadManageState 0
                                id
                                (Maybe.withDefault emptyManage (model.manage |> Maybe.map (\manage -> { manage | problem = Nothing })))
                                changed

                        _ ->
                            ( changed, Cmd.none )

                Err problem ->
                    let
                        base =
                            authProblem model problem
                    in
                    ( { base
                        | flash = FlashProblem problem
                        , manage = model.manage |> Maybe.map (\manage -> { manage | problem = Just problem })
                      }
                    , Cmd.none
                    )

        Loaded kind response ->
            let
                setCommunity result =
                    case result of
                        Ok community ->
                            updateManageRecord model
                                (\manage ->
                                    { manage
                                        | community = Ready community
                                        , readPolicy = visibilityText community.community.visibility
                                        , postPolicy =
                                            if community.community.postingRestrictedToMods then
                                                "managers"

                                            else
                                                "eligible_users"
                                        , followPolicy =
                                            if community.community.visibility == Domain.PrivateCommunity then
                                                "approval"

                                            else
                                                "open"
                                    }
                                )

                        Err problem ->
                            updateManageRecord model (\manage -> { manage | community = Failed problem, problem = Just problem })

                setRoster members result =
                    case result of
                        Ok page ->
                            updateManageRecord model
                                (\manage ->
                                    if members then
                                        { manage | members = Ready page }

                                    else
                                        { manage | managers = Ready page }
                                )

                        Err problem ->
                            updateManageRecord model
                                (\manage ->
                                    if members then
                                        { manage | members = Failed problem, problem = Just problem }

                                    else
                                        { manage | managers = Failed problem, problem = Just problem }
                                )

                setPage ready failed result =
                    case result of
                        Ok page ->
                            updateManageRecord model (ready page)

                        Err problem ->
                            updateManageRecord model (failed problem)
            in
            ( case kind of
                LoadManageCommunity _ ->
                    case Api.decodeResponse Domain.communityResponse response of
                        Ok data ->
                            updateManageRecord model
                                (\manage ->
                                    { manage
                                        | community = Ready data.communityView
                                        , managers = Ready { items = data.moderators, nextPage = Nothing, prevPage = Nothing }
                                        , readPolicy = visibilityText data.communityView.community.visibility
                                        , postPolicy =
                                            if data.communityView.community.postingRestrictedToMods then
                                                "managers"

                                            else
                                                "eligible_users"
                                        , followPolicy =
                                            if data.communityView.community.visibility == Domain.PrivateCommunity then
                                                "approval"

                                            else
                                                "open"
                                        , title = Maybe.withDefault "" data.communityView.community.title
                                        , sidebar = Maybe.withDefault "" data.communityView.community.sidebar
                                        , summary = Maybe.withDefault "" data.communityView.community.summary
                                        , nsfw = data.communityView.community.nsfw
                                        , visibility = visibilityText data.communityView.community.visibility
                                        , postingRestricted = data.communityView.community.postingRestrictedToMods
                                        , discussionLanguages = String.join "," (List.map String.fromInt data.discussionLanguages)
                                        , postUpvotes = voteModeText data.communityView.community.postUpvotes
                                        , postDownvotes = voteModeText data.communityView.community.postDownvotes
                                        , commentUpvotes = voteModeText data.communityView.community.commentUpvotes
                                        , commentDownvotes = voteModeText data.communityView.community.commentDownvotes
                                    }
                                )

                        Err problem ->
                            updateManageRecord model (\manage -> { manage | community = Failed problem, problem = Just problem })

                LoadMembers _ _ ->
                    setRoster True (Api.decodeResponse (Domain.page Domain.communityModeratorView) response)

                LoadManagers _ _ ->
                    setRoster False (Api.decodeResponse (Domain.page Domain.communityModeratorView) response)

                LoadFollowRequests _ _ ->
                    setPage
                        (\page -> \manage -> { manage | followRequests = Ready page })
                        (\problem -> \manage -> { manage | followRequests = Failed problem, problem = Just problem })
                        (Api.decodeResponse (Domain.page Domain.pendingFollow) response)

                LoadReports _ ->
                    setPage
                        (\page -> \manage -> { manage | reports = Ready page })
                        (\problem -> \manage -> { manage | reports = Failed problem, problem = Just problem })
                        (Api.decodeResponse (Domain.page Domain.reportView) response)

                LoadModlog _ _ ->
                    setPage
                        (\page -> \manage -> { manage | modlog = Ready page })
                        (\problem -> \manage -> { manage | modlog = Failed problem, problem = Just problem })
                        (Api.decodeResponse (Domain.page Domain.modlogView) response)
            , Cmd.none
            )


manageRequest : Context -> Working -> String -> String -> String -> String -> ( Working, Cmd Msg )
manageRequest context model key method url body =
    if Set.member key model.busy then
        ( model, Cmd.none )

    else
        ( { model | busy = Set.insert key model.busy }
        , Api.send context.csrf method url body (ActionDone (ManageAction key))
        )


manageActorRequest : Context -> Working -> String -> String -> String -> ( Working, Cmd Msg )
manageActorRequest context model key method section =
    case model.manage of
        Just manage ->
            manageActorRequestWith context model key method section manage.actor

        Nothing ->
            ( model, Cmd.none )


manageActorRequestFor : Context -> Working -> String -> String -> String -> String -> ( Working, Cmd Msg )
manageActorRequestFor context model key method section actor =
    manageActorRequestWith context model key method section actor


manageActorRequestWith : Context -> Working -> String -> String -> String -> String -> ( Working, Cmd Msg )
manageActorRequestWith context model key method section actor =
    if String.toInt actor == context.viewerId then
        ( model, Cmd.none )

    else if section == "managers" then
        manageRequest context
            model
            key
            "POST"
            "/community/mod"
            (Encode.encode 0
                (Encode.object
                    [ ( "community_id", Encode.int (String.toInt (communityId context.route) |> Maybe.withDefault 0) )
                    , ( "person_id", Encode.int (String.toInt actor |> Maybe.withDefault 0) )
                    , ( "added", Encode.bool (method == "POST") )
                    ]
                )
            )

    else
        ( model, Cmd.none )


communityBanRequest : Context -> Working -> String -> ( Working, Cmd Msg )
communityBanRequest context model method =
    case model.manage of
        Just manage ->
            if manage.banBusy || String.isEmpty (String.trim manage.banActor) || String.isEmpty (String.trim manage.banReason) then
                ( model, Cmd.none )

            else
                manageRequest context
                    model
                    ("community-ban-" ++ method)
                    "POST"
                    "/community/ban_user"
                    (Encode.encode 0
                        (Encode.object
                            ([ ( "community_id", Encode.int (String.toInt (communityId context.route) |> Maybe.withDefault 0) )
                             , ( "person_id", Encode.int (String.toInt (String.trim manage.banActor) |> Maybe.withDefault 0) )
                             , ( "ban", Encode.bool (method == "POST") )
                             , ( "reason", Encode.string (String.trim manage.banReason) )
                             ]
                                ++ (if String.isEmpty (String.trim manage.banExpires) then
                                        []

                                    else
                                        [ ( "expires_at", Encode.int (String.toInt (String.trim manage.banExpires) |> Maybe.withDefault 0) ) ]
                                   )
                            )
                        )
                    )

        Nothing ->
            ( model, Cmd.none )


managePage : Context -> Working -> Bool -> Int -> ( Working, Cmd Msg )
managePage context model members delta =
    case model.manage of
        Just manage ->
            let
                updated =
                    if members then
                        { manage | memberOffset = max 0 (manage.memberOffset + delta) }

                    else
                        { manage | managerOffset = max 0 (manage.managerOffset + delta) }
            in
            case context.route of
                Route.Manage id ->
                    loadManageState 0 id updated model

                _ ->
                    ( model, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


manageSectionPage : Context -> Working -> String -> Int -> ( Working, Cmd Msg )
manageSectionPage context model section delta =
    case model.manage of
        Just manage ->
            let
                updated =
                    if section == "follow" then
                        { manage | followRequestOffset = max 0 (manage.followRequestOffset + delta) }

                    else if section == "reports" then
                        { manage | reportOffset = max 0 (manage.reportOffset + delta) }

                    else
                        { manage | modlogOffset = max 0 (manage.modlogOffset + delta) }
            in
            case context.route of
                Route.Manage id ->
                    loadManageState 0 id updated model

                _ ->
                    ( model, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


managePostRequest : Context -> Working -> String -> ManagePostAction -> ( Working, Cmd Msg )
managePostRequest context model postId action =
    let
        key =
            "manage-post-" ++ postId ++ "-" ++ manageActionKey action
    in
    case action of
        RemoveCommunityPost ->
            manageRequest context
                model
                key
                "POST"
                "/post/remove"
                (Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (String.toInt postId |> Maybe.withDefault 0) ), ( "removed", Encode.bool True ), ( "reason", Encode.string "" ) ]))

        RestoreCommunityPost ->
            manageRequest context
                model
                key
                "POST"
                "/post/remove"
                (Encode.encode 0 (Encode.object [ ( "post_id", Encode.int (String.toInt postId |> Maybe.withDefault 0) ), ( "removed", Encode.bool False ), ( "reason", Encode.string "" ) ]))

        _ ->
            ( model, Cmd.none )


setManage : Working -> (ManageState -> ManageState) -> Cmd Msg -> ( Working, Cmd Msg )
setManage model transform command =
    ( { model | manage = Maybe.map transform model.manage }, command )


setField : String -> String -> ManageState -> ManageState
setField field value manage =
    case field of
        "title" ->
            { manage | title = value, problem = Nothing }

        "sidebar" ->
            { manage | sidebar = value, problem = Nothing }

        "summary" ->
            { manage | summary = value, problem = Nothing }

        "nsfw" ->
            { manage | nsfw = value == "true", problem = Nothing }

        "visibility" ->
            { manage | visibility = value, problem = Nothing }

        "postingRestricted" ->
            { manage | postingRestricted = value == "true", problem = Nothing }

        "discussionLanguages" ->
            { manage | discussionLanguages = value, problem = Nothing }

        "postUpvotes" ->
            { manage | postUpvotes = value, problem = Nothing }

        "postDownvotes" ->
            { manage | postDownvotes = value, problem = Nothing }

        "commentUpvotes" ->
            { manage | commentUpvotes = value, problem = Nothing }

        "commentDownvotes" ->
            { manage | commentDownvotes = value, problem = Nothing }

        _ ->
            manage


updateManageRecord : Working -> (ManageState -> ManageState) -> Working
updateManageRecord model transform =
    { model | manage = Maybe.map transform model.manage }


loadManageState : Int -> String -> ManageState -> Working -> ( Working, Cmd Msg )
loadManageState epoch id manage model =
    ( { model | manage = Just manage }
    , Cmd.batch
        [ Api.get ("/community?id=" ++ urlEncode id) (Loaded (LoadManageCommunity id))
        , Api.get ("/community/pending_follows/list?community_id=" ++ urlEncode id ++ "&limit=20") (Loaded (LoadFollowRequests id manage.followRequestOffset))
        , Api.get ("/report/list?unresolved_only=true&community_id=" ++ urlEncode id ++ "&limit=20") (Loaded (LoadReports id))
        , Api.get ("/modlog?community_id=" ++ urlEncode id ++ "&limit=20") (Loaded (LoadModlog id manage.modlogOffset))
        ]
    )


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


voteModeText : Domain.VoteMode -> String
voteModeText mode =
    case mode of
        Domain.AllVotes ->
            "all"

        Domain.LocalVotes ->
            "local"

        Domain.SubscribedVotes ->
            "subscribed"

        Domain.DisabledVotes ->
            "disable"


parseIds : String -> List Int
parseIds value =
    value
        |> String.split ","
        |> List.filterMap (String.trim >> String.toInt)


followerIdFor : String -> ManageState -> Int
followerIdFor actor manage =
    case manage.followRequests of
        Ready page ->
            page.items
                |> List.filterMap
                    (\request ->
                        if request.person.apId == actor then
                            Just request.person.id

                        else
                            Nothing
                    )
                |> List.head
                |> Maybe.withDefault 0

        _ ->
            0


resolvePath : String -> Working -> String
resolvePath id model =
    let
        kind =
            case model.manage of
                Just manage ->
                    case manage.reports of
                        Ready page ->
                            page.items
                                |> List.filterMap
                                    (\reportValue ->
                                        if String.fromInt (reportId reportValue) == id then
                                            Just (reportKind reportValue)

                                        else
                                            Nothing
                                    )
                                |> List.head
                                |> Maybe.withDefault "post"

                        _ ->
                            "post"

                Nothing ->
                    "post"
    in
    "/" ++ kind ++ "/report/resolve"


reportId : Domain.ReportView -> Int
reportId reportValue =
    case reportValue of
        Domain.PostReportView report _ _ _ _ ->
            report.id

        Domain.CommentReportView report _ _ _ _ _ ->
            report.id

        Domain.CommunityReportView report _ _ _ ->
            report.id

        Domain.PrivateMessageReportView value _ _ _ _ _ _ ->
            value


reportKind : Domain.ReportView -> String
reportKind reportValue =
    case reportValue of
        Domain.PostReportView _ _ _ _ _ ->
            "post"

        Domain.CommentReportView _ _ _ _ _ _ ->
            "comment"

        Domain.CommunityReportView _ _ _ _ ->
            "community"

        Domain.PrivateMessageReportView _ _ _ _ _ _ _ ->
            "private_message"
