module App.State exposing (ConfirmationAction(..), Model, Msg(..))

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Browser
import Browser.Navigation as Navigation
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.AccountSettings as AccountSettings
import Feature.Auth.State
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State
import Feature.CommunityManage.Update as Manage
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
import Feature.SiteAdmin.State
import Feature.SiteAdmin.Update as SiteAdmin
import Feature.SiteConfiguration as SiteConfiguration
import Feature.SiteMedia as SiteMedia
import Feature.SiteSetup as SiteSetup
import Feature.SiteUsers as SiteUsers
import Feature.Taglines as Taglines
import File exposing (File)
import Generated.I18n as Translations
import Http
import Json.Decode as Decode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Locale exposing (Locale(..))
import Localization
import Remote exposing (Remote)
import Ui.Formatting exposing (Formatting)
import Url exposing (Url)


type alias Model =
    { key : Navigation.Key
    , url : Url
    , route : Route.Route
    , routeEpoch : Int
    , authGeneration : Int
    , auth : AuthState
    , site : Maybe Domain.SiteView
    , captchaEnabled : Bool
    , donationPrompt : Bool
    , active : Maybe Active
    , requested : Locale
    , bootFailed : Bool
    , loading : Localization.State
    , drawerOpen : Bool
    , wideLayout : Bool
    , drawerProfile : Remote Domain.PersonView
    , dialog : Maybe ConfirmationAction
    , flash : Flash
    , formatted : Maybe Formatting
    , account : Feature.Auth.State.Model
    , editorPage : Feature.Editor.State.Model
    , management : Feature.CommunityManage.State.Model
    , accountContent : AccountContent.Model
    , accountSettings : AccountSettings.Model
    , accountBlocks : AccountBlocks.Model
    , report : Report.Model
    , siteAdmin : Feature.SiteAdmin.State.Model
    , profile : Profile.Model
    , searchPage : Search.Model
    , instances : Instances.Model
    , pendingFollows : PendingFollows.Model
    , registrationApplications : RegistrationApplications.Model
    , siteSetup : SiteSetup.Model
    , taglines : Taglines.Model
    , customEmoji : CustomEmoji.Model
    , oauthProviders : OAuthProviders.Model
    , oauthLogin : OAuthLogin.Model
    , siteUsers : SiteUsers.Model
    , siteMedia : SiteMedia.Model
    , siteConfiguration : SiteConfiguration.Model
    , federationPolicy : FederationPolicy.Model
    , notificationsPage : Notifications.Model
    , multiCommunity : MultiCommunity.Model
    , communityCreate : CommunityCreate.Model
    , posts : Post.Model
    , communityPage : Community.Model
    , commentTarget : Remote ()
    , externalInteraction : Remote ()
    , feed : Feed.Model
    }


type ConfirmationAction
    = DeletePostDialog String
    | ResolveReportDialog String String
    | RemoveSiteBanDialog
    | RemoveCommunityBanDialog
    | RemoveBlockDialog String String
    | SetMultiCommunityDeletedDialog Bool
    | DeleteTaglineDialog Int String
    | DeleteEmojiDialog Int String
    | DeleteOAuthProviderDialog Int String
    | ChangeSiteAdminDialog Int String Bool
    | RemoveSiteImageDialog String


type Msg
    = Navigate Browser.UrlRequest
    | UrlChanged Url
    | LanguageSelected String
    | BootLanguageSelected String
    | RetryLocalization
    | RetryPage
    | CatalogResult Localization.Pending (Result Http.Error (Translations.I18n -> Translations.I18n))
    | Incoming Decode.Value
    | SessionLoaded Int (Result Api.Problem Domain.MyUserInfo)
    | SiteLoaded (Result Api.Problem Domain.GetSiteResponse)
    | DrawerProfileLoaded (Result Api.Problem Domain.PersonView)
    | OpenDrawer
    | CloseDrawer
    | DrawerClosed
    | OpenDeleteDialog String
    | OpenConfirmation ConfirmationAction
    | CloseDialog
    | ConfirmDialog
    | Noop
    | EditorMessage Editor.Msg
    | EditorResponse Int Editor.Msg
    | ManageMessage Manage.Msg
    | ManageResponse Int Manage.Msg
    | AccountContentMessage AccountContent.Msg
    | AccountContentResponse Int AccountContent.Msg
    | AccountSettingsMessage AccountSettings.Msg
    | AccountSettingsResponse Int AccountSettings.Msg
    | AccountBlocksMessage AccountBlocks.Msg
    | AccountBlocksResponse Int AccountBlocks.Msg
    | ReportMessage Report.Msg
    | ReportResponse Int Report.Msg
    | SiteAdminMessage SiteAdmin.Msg
    | SiteAdminResponse Int SiteAdmin.Msg
    | AuthMessage Auth.Msg
    | AuthResponse Int Auth.Msg
    | ProfileMessage Profile.Msg
    | ProfileResponse Int Profile.Msg
    | SearchMessage Search.Msg
    | SearchResponse Int Search.Msg
    | InstancesLoaded Int Api.Response
    | PendingFollowsLoaded Int Api.Response
    | PendingFollowDecision Int Int Bool
    | PendingFollowDecided Int Api.Response
    | RegistrationApplicationsLoaded Int Api.Response
    | RegistrationReasonChanged Int String
    | RegistrationDecision Int Bool
    | RegistrationDecided Int Int Api.Response
    | SiteSetupChanged SiteSetup.Field String
    | SiteSetupSubmitted
    | SiteSetupFinished Int Api.Response
    | TaglinesLoaded Int Api.Response
    | TaglineNewChanged String
    | TaglineEditChanged Int String
    | TaglineSave (Maybe Int)
    | TaglineSaved Int Api.Response
    | EmojiLoaded Int Api.Response
    | EmojiChanged CustomEmoji.Field String
    | EmojiEdit CustomEmoji.Emoji
    | EmojiCancel
    | EmojiSubmit
    | EmojiSaved Int Api.Response
    | OAuthProvidersLoaded Int Api.Response
    | OAuthProviderFieldChanged String String
    | OAuthProviderFlagChanged String Bool
    | OAuthProviderEdit OAuthProviders.Provider
    | OAuthProviderCancel
    | OAuthProviderSubmit
    | OAuthProviderSaved Int Api.Response
    | OAuthUsernameChanged String
    | OAuthAnswerChanged String
    | OAuthTotpChanged String
    | OAuthStart Domain.PublicOAuthProvider
    | OAuthSubmit
    | OAuthFinished Int Api.Response
    | OAuthAccountLoaded Int (Result Api.Problem Domain.MyUserInfo)
    | SiteUsersLoaded Int Api.Response
    | SiteAdminChanged Int Api.Response
    | SiteMediaLoaded Int Api.Response
    | SiteConfigurationLoaded Int Api.Response
    | SiteConfigurationChanged String String
    | SiteConfigurationToggled String Bool
    | SiteConfigurationSave
    | SiteConfigurationSaved Int Api.Response
    | SiteConfigurationImageSelected String (Maybe File)
    | SiteConfigurationImageRemove String
    | SiteConfigurationImageFinished Int String Bool Api.Response
    | FederationPolicyLoaded Int Api.Response
    | FederationPolicyChanged FederationPolicy.Field String
    | FederationPolicySubmit
    | FederationPolicySaved Int Api.Response
    | NotificationsMessage Notifications.Msg
    | NotificationsResponse Int Notifications.Msg
    | MultiCommunityMessage MultiCommunity.Msg
    | MultiCommunityResponse Int MultiCommunity.Msg
    | CommunityCreateMessage CommunityCreate.Msg
    | CommunityCreateResponse Int CommunityCreate.Msg
    | PostMessage Post.Msg
    | PostResponse Int Post.Msg
    | CommentTargetLoaded Int Api.Response
    | ExternalInteractionLoaded Int Api.Response
    | FeedResponse Int Feed.Msg
    | CommunityMessage Community.Msg
    | CommunityResponse Int Community.Msg
    | DismissFlash
    | DismissDonation
