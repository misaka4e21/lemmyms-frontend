module App.Init exposing (init)

import App.Feedback exposing (Flash(..))
import App.Localization exposing (loadCatalog)
import App.Routing exposing (loadSession)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.AccountSettings as AccountSettings
import Feature.Auth.State
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State
import Feature.CustomEmoji as CustomEmoji
import Feature.Editor.State
import Feature.Editor.Update as Editor
import Feature.FederationPolicy as FederationPolicy
import Feature.Feed as Feed
import Feature.Instances as Instances
import Feature.MultiCommunity as MultiCommunity
import Feature.Notifications as Notifications
import Feature.OAuthLogin as OAuthLogin
import Feature.OAuthProviders as OAuthProviders
import Feature.PendingFollows as PendingFollows
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.RegistrationApplications as RegistrationApplications
import Feature.Report as Report
import Feature.Search as Search
import Feature.SiteAdmin.State as SiteAdminState
import Feature.SiteConfiguration as SiteConfiguration
import Feature.SiteMedia as SiteMedia
import Feature.SiteSetup as SiteSetup
import Feature.SiteUsers as SiteUsers
import Feature.Taglines as Taglines
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
            , captchaEnabled = False
            , donationPrompt = False
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
            , instances = Instances.initial
            , pendingFollows = PendingFollows.initial
            , registrationApplications = RegistrationApplications.initial
            , siteSetup = SiteSetup.initial
            , taglines = Taglines.initial
            , customEmoji = CustomEmoji.initial
            , oauthProviders = OAuthProviders.initial
            , oauthLogin = OAuthLogin.initial
            , siteUsers = SiteUsers.initial
            , siteMedia = SiteMedia.initial
            , siteConfiguration = SiteConfiguration.initial
            , federationPolicy = FederationPolicy.initial
            , notificationsPage = Notifications.initial
            , multiCommunity = MultiCommunity.initial
            , profile = Profile.initial
            , editorPage = Feature.Editor.State.initial
            , communityCreate = CommunityCreate.initial
            , management = Feature.CommunityManage.State.initial
            , accountContent = AccountContent.initial
            , accountSettings = AccountSettings.initial
            , accountBlocks = AccountBlocks.initial
            , report = Report.initial
            , siteAdmin = SiteAdminState.initial
            , commentTarget = NotAsked
            , externalInteraction = NotAsked
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
