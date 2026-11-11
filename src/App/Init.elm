module App.Init exposing (init)

import App.Feedback exposing (Flash(..))
import App.Localization exposing (loadCatalog)
import App.Routing exposing (loadSession)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.Auth.State
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State
import Feature.Editor.State
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Report as Report
import Feature.Search as Search
import Feature.SiteAdmin.State as SiteAdminState
import Json.Decode as Decode
import Lemmy.Route as Route
import Locale exposing (Locale(..))
import Localization exposing (LoadKind(..))
import Remote exposing (Remote(..))
import Url exposing (Url)


type alias Flags =
    { languages : List String
    , savedLocale : Maybe String
    , wideLayout : Bool
    }


init : Decode.Value -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init rawFlags url key =
    let
        flags =
            Decode.decodeValue flagsDecoder rawFlags |> Result.withDefault defaultFlags

        requested =
            Locale.negotiate flags.savedLocale flags.languages

        ( loading, request ) =
            Localization.start Startup requested Localization.initial

        route =
            Route.parse url

        account =
            Feature.Auth.State.initial (verificationToken route)

        accountWithReset =
            case route of
                Route.PasswordChange token ->
                    Feature.Auth.State.withResetToken token account

                _ ->
                    account

        model =
            { key = key
            , url = url
            , route = route
            , routeEpoch = 0
            , authGeneration = 0
            , auth = CheckingSession
            , site = Nothing
            , active = Nothing
            , requested = requested
            , bootFailed = False
            , loading = loading
            , drawerOpen = flags.wideLayout
            , wideLayout = flags.wideLayout
            , drawerProfile = NotAsked
            , dialog = Nothing
            , flash = NoFlash
            , formatted = Nothing
            , account = accountWithReset
            , posts = Post.initial
            , feed = Feed.initial
            , communityPage = Community.initial
            , searchPage = Search.initial
            , notificationsPage = Notifications.initial
            , profile = Profile.initial
            , editorPage = Feature.Editor.State.initial
            , communityCreate = CommunityCreate.initial
            , management = Feature.CommunityManage.State.initial
            , accountContent = AccountContent.initial
            , accountBlocks = AccountBlocks.initial
            , report = Report.initial
            , siteAdmin = SiteAdminState.initial
            , commentTarget = NotAsked
            }
    in
    ( model, Cmd.batch [ loadCatalog request, loadSession model ] )


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map3 Flags
        (Decode.field "languages" (Decode.list Decode.string))
        (Decode.field "savedLocale" (Decode.nullable Decode.string))
        (Decode.field "wideLayout" Decode.bool)


defaultFlags : Flags
defaultFlags =
    { languages = [ "en-US" ]
    , savedLocale = Nothing
    , wideLayout = False
    }


verificationToken : Route.Route -> String
verificationToken route =
    case route of
        Route.VerifyEmail token ->
            token

        _ ->
            ""
