module Feature.SiteAdmin.Update exposing (Action(..), LoadKind(..), Msg(..), Outcome, loadBans, loadModlog, loadReports, loadSettings, update)

import Api
import App.Feedback exposing (Flash(..))
import Dict
import Feature.SiteAdmin.State exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Set exposing (Set)
import Url exposing (Url)


type Msg
    = Loaded LoadKind Api.Response
    | SettingsLoaded Api.Response
    | UpvotesChanged Bool
    | DownvotesChanged Bool
    | SaveSettings
    | SettingsSaved Api.Response
    | ReportStateChanged String
    | ReportCommunityChanged String
    | ApplyReportFilter
    | ReportNoteChanged String String
    | ResolveReport String String
    | ReportResolved String String Api.Response
    | ModlogCommunityChanged String
    | ApplyModlogFilter
    | BanActorChanged String
    | BanReasonChanged String
    | BanExpiresChanged String
    | CreateBan
    | RemoveBan
    | BanResolved Bool (Result Api.Problem Int)
    | BanDone Action Api.Response


type LoadKind
    = LoadReports
    | LoadModlog


type Action
    = BanAction


type alias Context =
    { csrf : String, url : Url }


type alias Outcome =
    { flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshModlog : Bool
    }


type alias Working =
    { model : Model
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshModlog : Bool
    }


update : Context -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update context message state =
    let
        ( next, command ) =
            updateWorking context
                message
                { model = state
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                , refreshModlog = False
                }
    in
    ( next.model
    , command
    , { flash = next.flash
      , sessionProblem = next.sessionProblem
      , navigation = next.navigation
      , refreshModlog = next.refreshModlog
      }
    )


updateWorking : Context -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking context message state =
    let
        model =
            state.model
    in
    case message of
        Loaded kind response ->
            let
                updated =
                    case kind of
                        LoadReports ->
                            { model | reports = decodePage (Domain.page Domain.reportView) response }

                        LoadModlog ->
                            { model | modlog = decodePage (Domain.page Domain.modlogView) response }
            in
            ( { state
                | model = updated
                , sessionProblem = problemFor response
              }
            , Cmd.none
            )

        SettingsLoaded response ->
            case Api.decodeResponse Domain.siteView response of
                Ok settings ->
                    ( { state
                        | model =
                            { model
                                | voteSettings = Ready settings.localSite
                                , upvotesEnabled = settings.localSite.defaultPostUpvotes /= Domain.DisabledVotes
                                , downvotesEnabled = settings.localSite.defaultPostDownvotes /= Domain.DisabledVotes
                                , settingsProblem = Nothing
                            }
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { state
                        | model =
                            { model
                                | voteSettings = Failed problem
                                , settingsProblem = Just problem
                            }
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )

        UpvotesChanged value ->
            ( { state | model = { model | upvotesEnabled = value, settingsProblem = Nothing } }, Cmd.none )

        DownvotesChanged value ->
            ( { state | model = { model | downvotesEnabled = value, settingsProblem = Nothing } }, Cmd.none )

        SaveSettings ->
            if model.settingsBusy then
                ( state, Cmd.none )

            else
                ( { state | model = { model | settingsBusy = True, settingsProblem = Nothing } }
                , Api.send context.csrf
                    "PUT"
                    "/site"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "default_post_upvotes"
                              , Encode.string
                                    (if model.upvotesEnabled then
                                        "all"

                                     else
                                        "disable"
                                    )
                              )
                            , ( "default_post_downvotes"
                              , Encode.string
                                    (if model.downvotesEnabled then
                                        "all"

                                     else
                                        "disable"
                                    )
                              )
                            ]
                        )
                    )
                    SettingsSaved
                )

        SettingsSaved response ->
            case Api.decodeResponse Domain.siteView response of
                Ok settings ->
                    ( { state
                        | model =
                            { model
                                | voteSettings = Ready settings.localSite
                                , upvotesEnabled = settings.localSite.defaultPostUpvotes /= Domain.DisabledVotes
                                , downvotesEnabled = settings.localSite.defaultPostDownvotes /= Domain.DisabledVotes
                                , settingsBusy = False
                                , settingsProblem = Nothing
                            }
                        , flash = FlashSaved
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { state
                        | model = { model | settingsBusy = False, settingsProblem = Just problem }
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )

        ReportStateChanged value ->
            ( { state | model = { model | reportState = value } }, Cmd.none )

        ReportCommunityChanged value ->
            ( { state | model = { model | reportCommunity = value } }, Cmd.none )

        ApplyReportFilter ->
            ( { state | navigation = Just (reportsPath model.reportState model.reportCommunity) }, Cmd.none )

        ReportNoteChanged id value ->
            ( { state | model = { model | reportNotes = Dict.insert id value model.reportNotes } }, Cmd.none )

        ResolveReport id resolution ->
            if Set.member id model.reportBusy then
                ( state, Cmd.none )

            else
                ( { state | model = { model | reportBusy = Set.insert id model.reportBusy } }
                , Api.send context.csrf
                    "PUT"
                    (reportResolvePath id model)
                    (Encode.encode 0
                        (Encode.object
                            [ ( "report_id", Encode.int (String.toInt id |> Maybe.withDefault 0) )
                            , ( "resolved", Encode.bool (resolution == "resolved") )
                            , ( "conclusion", Encode.string (Dict.get id model.reportNotes |> Maybe.withDefault "") )
                            ]
                        )
                    )
                    (ReportResolved id resolution)
                )

        ReportResolved id _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { state
                        | model =
                            { model
                                | reportBusy = Set.remove id model.reportBusy
                                , reports = Loading
                            }
                        , flash = FlashSaved
                        , refreshModlog = True
                      }
                    , reportsCommand model
                    )

                Err problem ->
                    ( { state
                        | model =
                            { model
                                | reportBusy = Set.remove id model.reportBusy
                                , reports = Loading
                            }
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , reportsCommand model
                    )

        ModlogCommunityChanged value ->
            ( { state | model = { model | modlogCommunity = value } }, Cmd.none )

        ApplyModlogFilter ->
            ( { state | navigation = Just (modlogPath model.modlogCommunity) }, Cmd.none )

        BanActorChanged value ->
            ( { state | model = { model | banActor = value, banProblem = Nothing } }, Cmd.none )

        BanReasonChanged value ->
            ( { state | model = { model | banReason = value, banProblem = Nothing } }, Cmd.none )

        BanExpiresChanged value ->
            ( { state | model = { model | banExpires = value, banProblem = Nothing } }, Cmd.none )

        CreateBan ->
            resolveBan context state True

        RemoveBan ->
            resolveBan context state False

        BanResolved ban result ->
            case result of
                Ok personId ->
                    sendBan context state personId ban

                Err problem ->
                    let
                        current =
                            state.model
                    in
                    ( { state | model = { current | banBusy = False, banProblem = Just problem } }
                    , Cmd.none
                    )

        BanDone _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { state
                        | model =
                            { model
                                | banBusy = False
                                , banActor = ""
                                , banReason = ""
                                , banExpires = ""
                                , banProblem = Nothing
                            }
                        , flash = FlashSaved
                        , refreshModlog = True
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { state
                        | model = { model | banBusy = False, banProblem = Just problem }
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )


resolveBan : Context -> Working -> Bool -> ( Working, Cmd Msg )
resolveBan context state ban =
    let
        model =
            state.model
    in
    if model.banBusy || String.isEmpty (String.trim model.banActor) || String.isEmpty (String.trim model.banReason) then
        ( state, Cmd.none )

    else
        ( { state | model = { model | banBusy = True, banProblem = Nothing } }
        , Api.get
            ("/person?username=" ++ Url.percentEncode (actorToUsername model.banActor))
            (BanResolved ban << Api.decodeResponse (Decode.field "person_view" Domain.personView |> Decode.map (.person >> .id)))
        )


sendBan : Context -> Working -> Int -> Bool -> ( Working, Cmd Msg )
sendBan context state personId ban =
    let
        model =
            state.model
    in
    ( state
    , Api.send context.csrf
        "POST"
        "/admin/ban"
        (Encode.encode 0
            (Encode.object
                ([ ( "person_id", Encode.int personId )
                 , ( "ban", Encode.bool ban )
                 , ( "reason", Encode.string (String.trim model.banReason) )
                 ]
                    ++ (if String.isEmpty (String.trim model.banExpires) then
                            []

                        else
                            [ ( "expires_at", Encode.int (String.toInt (String.trim model.banExpires) |> Maybe.withDefault 0) ) ]
                       )
                )
            )
        )
        (BanDone BanAction)
    )


actorToUsername : String -> String
actorToUsername actor =
    let
        value =
            String.trim actor
    in
    if String.startsWith "http://" value || String.startsWith "https://" value then
        case String.split "/" value of
            _ :: _ :: host :: rest ->
                Maybe.withDefault value (List.head (List.reverse rest)) ++ "@" ++ host

            _ ->
                value

    else
        value


decodePage : Decode.Decoder (Domain.Page a) -> Api.Response -> Remote (Domain.Page a)
decodePage decoder response =
    case Api.decodeResponse decoder response of
        Ok page ->
            Ready page

        Err problem ->
            Failed problem


problemFor : Api.Response -> Maybe Api.Problem
problemFor response =
    if response.status >= 200 && response.status < 300 then
        Nothing

    else
        sessionProblem { status = response.status, detail = response.body }


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


urlEncode : String -> String
urlEncode =
    Url.percentEncode


reportsPath : String -> String -> String
reportsPath state community =
    "/reports"
        ++ query
            [ ( "state", state )
            , ( "community_id", community )
            ]


reportsApiPath : String -> String -> Maybe String -> String
reportsApiPath state community cursorValue =
    "/report/list"
        ++ query
            [ ( "unresolved_only"
              , if state == "open" then
                    "true"

                else
                    ""
              )
            , ( "community_id", community )
            , ( "limit", "20" )
            , ( "page_cursor", Maybe.withDefault "" cursorValue )
            ]


reportResolvePath : String -> Model -> String
reportResolvePath id model =
    let
        kind =
            case model.reports of
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

        Domain.PrivateMessageReportView id _ _ _ _ _ _ ->
            id


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


modlogPath : String -> String
modlogPath community =
    "/modlog" ++ query [ ( "community_id", community ) ]


modlogApiPath : String -> Maybe String -> String
modlogApiPath community cursorValue =
    "/modlog" ++ query [ ( "community_id", community ), ( "limit", "20" ), ( "page_cursor", Maybe.withDefault "" cursorValue ) ]


query : List ( String, String ) -> String
query values =
    values
        |> List.filter (\( _, value ) -> not (String.isEmpty (String.trim value)))
        |> List.map (\( key, value ) -> key ++ "=" ++ Url.percentEncode value)
        |> (\items ->
                if List.isEmpty items then
                    ""

                else
                    "?" ++ String.join "&" items
           )


loadSettings : Model -> ( Model, Cmd Msg )
loadSettings model =
    ( { model | voteSettings = Loading, settingsProblem = Nothing }
    , Api.get "/site" SettingsLoaded
    )


loadReports : Url -> Model -> ( Model, Cmd Msg )
loadReports url model =
    let
        state =
            Route.query "state" url
                |> (\value ->
                        if String.isEmpty value then
                            model.reportState

                        else
                            value
                   )

        community =
            Route.query "community_id" url

        cursorValue =
            Route.cursor url

        updated =
            { model | reports = Loading, reportState = state, reportCommunity = community, reportCursor = cursorValue }
    in
    ( updated, reportsCommand updated )


loadModlog : Route.Route -> Url -> Model -> ( Model, Cmd Msg )
loadModlog route url model =
    let
        community =
            case route of
                Route.Modlog (Just id) ->
                    String.fromInt id

                _ ->
                    Route.query "community_id" url

        cursorValue =
            Route.cursor url

        updated =
            { model | modlog = Loading, modlogCommunity = community, modlogCursor = cursorValue }
    in
    ( updated, modlogCommand updated )


loadBans : Model -> ( Model, Cmd Msg )
loadBans model =
    ( model, Cmd.none )


reportsCommand : Model -> Cmd Msg
reportsCommand model =
    Api.get (reportsApiPath model.reportState model.reportCommunity model.reportCursor) (Loaded LoadReports)


modlogCommand : Model -> Cmd Msg
modlogCommand model =
    Api.get (modlogApiPath model.modlogCommunity model.modlogCursor) (Loaded LoadModlog)
