module Main exposing (main)

import Api
import App.Access exposing (authProblem)
import App.Browser exposing (receiveIncoming)
import App.Features exposing (updateAccountBlocks, updateAccountContent, updateAccountSettings, updateAuth, updateCommunity, updateCommunityCreate, updateEditor, updateFeed, updateManage, updateMultiCommunity, updateNotifications, updatePost, updateProfile, updateReport, updateSearch, updateSiteAdmin)
import App.Feedback exposing (Flash(..))
import App.Init exposing (init)
import App.Localization exposing (beginStartup, resolveCatalog, selectLocale)
import App.Routing exposing (loadRoute, unreadCommand)
import App.Session exposing (AuthState(..))
import App.State exposing (ConfirmationAction(..), Model, Msg(..))
import App.View exposing (view)
import Browser
import Browser.Navigation as Navigation
import Dict
import Feature.AccountBlocks as AccountBlocks
import Feature.Auth.Update as Auth
import Feature.CommunityManage.Update as Manage
import Feature.CustomEmoji as CustomEmoji
import Feature.ExternalInteraction as ExternalInteraction
import Feature.FederationPolicy as FederationPolicy
import Feature.Instances as Instances
import Feature.MultiCommunity as MultiCommunity
import Feature.OAuthLogin as OAuthLogin
import Feature.OAuthProviders as OAuthProviders
import Feature.PendingFollows as PendingFollows
import Feature.Post as Post
import Feature.RegistrationApplications as RegistrationApplications
import Feature.SiteAdmin.Update as SiteAdmin
import Feature.SiteConfiguration as SiteConfiguration
import Feature.SiteMedia as SiteMedia
import Feature.SiteSetup as SiteSetup
import Feature.SiteUsers as SiteUsers
import Feature.Taglines as Taglines
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Locale exposing (Locale(..))
import Ports exposing (closeDialog, focus, incoming, openDialog, setTheme)
import Remote exposing (Remote(..))
import Set
import Ui.PostCard exposing (deleteTriggerId)
import Url


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = Navigate
        , onUrlChange = UrlChanged
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Navigate request ->
            case request of
                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Navigation.load href )

        UrlChanged url ->
            let
                changed =
                    { model
                        | url = url
                        , route = Route.parse url
                        , routeEpoch = model.routeEpoch + 1
                        , drawerOpen =
                            if model.wideLayout then
                                model.drawerOpen

                            else
                                False
                        , dialog = Nothing
                    }

                ( loaded, command ) =
                    loadRoute changed

                focusCommand =
                    case changed.route of
                        Route.Post _ (Just _) ->
                            Cmd.none

                        _ ->
                            focus "main-heading"
            in
            ( loaded, Cmd.batch [ command, unreadCommand loaded, closeDialog "navigation-drawer", focusCommand ] )

        LanguageSelected raw ->
            selectLocale raw model

        BootLanguageSelected raw ->
            case Locale.fromString raw of
                Just target ->
                    beginStartup target model

                Nothing ->
                    ( model, Cmd.none )

        RetryLocalization ->
            beginStartup model.requested model

        RetryPage ->
            let
                ( loaded, command ) =
                    loadRoute { model | routeEpoch = model.routeEpoch + 1 }
            in
            ( loaded, Cmd.batch [ command, unreadCommand loaded ] )

        CatalogResult request result ->
            resolveCatalog request result model

        Incoming value ->
            receiveIncoming value model

        SiteLoaded result ->
            case result of
                Ok site ->
                    let
                        previous =
                            model.oauthLogin
                    in
                    ( { model | site = Just site.siteView, captchaEnabled = site.captchaEnabled, oauthLogin = { previous | providers = site.oauthProviders } }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        SessionLoaded generation result ->
            if generation /= model.authGeneration then
                ( model, Cmd.none )

            else
                let
                    changed =
                        case result of
                            Ok identity ->
                                { model
                                    | auth = Authenticated identity
                                    , drawerProfile = Loading
                                    , donationPrompt = identity.localUserView.localUser.lastDonationNotificationAt == Nothing
                                }

                            Err problem ->
                                { model
                                    | auth = Anonymous
                                    , drawerProfile = NotAsked
                                    , flash =
                                        if problem.status == 401 then
                                            model.flash

                                        else
                                            FlashProblem problem
                                }

                    ( loaded, command ) =
                        loadRoute changed
                in
                ( loaded, Cmd.batch [ command, unreadCommand loaded, loadDrawerProfile changed, themeCommand changed ] )

        DrawerProfileLoaded result ->
            case model.auth of
                Authenticated _ ->
                    case result of
                        Ok profile ->
                            ( { model | drawerProfile = Ready profile }, Cmd.none )

                        Err problem ->
                            if problem.status == 401 then
                                ( authProblem model problem, Cmd.none )

                            else
                                ( { model | drawerProfile = Failed problem }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        OpenDrawer ->
            if model.wideLayout then
                ( { model | drawerOpen = True }, Cmd.none )

            else
                ( { model | drawerOpen = True }, openDialog "navigation-drawer" )

        CloseDrawer ->
            if model.wideLayout then
                ( { model | drawerOpen = False }, focus "menu-button" )

            else
                ( { model | drawerOpen = False }, Cmd.batch [ closeDialog "navigation-drawer", focus "menu-button" ] )

        DrawerClosed ->
            ( { model | drawerOpen = False }, Cmd.none )

        OpenDeleteDialog id ->
            ( { model | dialog = Just (DeletePostDialog id) }, openDialog "confirmation-dialog" )

        OpenConfirmation action ->
            ( { model | dialog = Just action }, openDialog "confirmation-dialog" )

        CloseDialog ->
            ( { model | dialog = Nothing }
            , Cmd.batch
                [ closeDialog "confirmation-dialog"
                , case model.dialog of
                    Just action ->
                        focus (confirmationTriggerId action)

                    Nothing ->
                        Cmd.none
                ]
            )

        ConfirmDialog ->
            case model.dialog of
                Just action ->
                    let
                        ( changed, command ) =
                            confirmAction action { model | dialog = Nothing, flash = NoFlash }
                    in
                    ( changed, Cmd.batch [ command, closeDialog "confirmation-dialog", focus "main-heading" ] )

                Nothing ->
                    ( model, Cmd.none )

        Noop ->
            ( model, Cmd.none )

        EditorMessage event ->
            updateEditor event model

        EditorResponse epoch event ->
            if epoch == model.routeEpoch then
                updateEditor event model

            else
                ( model, Cmd.none )

        ManageMessage event ->
            updateManage event model

        ManageResponse epoch event ->
            if epoch == model.routeEpoch then
                updateManage event model

            else
                ( model, Cmd.none )

        AccountContentMessage event ->
            updateAccountContent event model

        AccountContentResponse epoch event ->
            if epoch == model.routeEpoch then
                updateAccountContent event model

            else
                ( model, Cmd.none )

        AccountSettingsMessage event ->
            updateAccountSettings event model

        AccountSettingsResponse epoch event ->
            if epoch == model.routeEpoch then
                updateAccountSettings event model

            else
                ( model, Cmd.none )

        AccountBlocksMessage event ->
            updateAccountBlocks event model

        AccountBlocksResponse epoch event ->
            if epoch == model.routeEpoch then
                updateAccountBlocks event model

            else
                ( model, Cmd.none )

        ReportMessage event ->
            updateReport event model

        ReportResponse epoch event ->
            if epoch == model.routeEpoch then
                updateReport event model

            else
                ( model, Cmd.none )

        SiteAdminMessage event ->
            updateSiteAdmin event model

        SiteAdminResponse epoch event ->
            if epoch == model.routeEpoch then
                updateSiteAdmin event model

            else
                ( model, Cmd.none )

        AuthMessage event ->
            updateAuth event model

        AuthResponse epoch event ->
            if epoch == model.routeEpoch || Auth.isSessionAction event then
                updateAuth event model

            else
                ( model, Cmd.none )

        ProfileMessage event ->
            updateProfile event model

        ProfileResponse epoch event ->
            if epoch == model.routeEpoch then
                updateProfile event model

            else
                ( model, Cmd.none )

        SearchMessage event ->
            updateSearch event model

        InstancesLoaded epoch response ->
            if epoch == model.routeEpoch then
                ( { model | instances = Remote.fromResult (Api.decodeResponse Instances.decoder response) }, Cmd.none )

            else
                ( model, Cmd.none )

        PendingFollowsLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.pendingFollows
                in
                ( { model | pendingFollows = { previous | requests = Remote.fromResult (Api.decodeResponse (Domain.page Domain.pendingFollow) response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        RegistrationApplicationsLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.registrationApplications
                in
                ( { model | registrationApplications = { previous | requests = Remote.fromResult (Api.decodeResponse (Domain.page RegistrationApplications.decoder) response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        RegistrationReasonChanged id reason ->
            let
                previous =
                    model.registrationApplications
            in
            ( { model | registrationApplications = { previous | drafts = Dict.insert id reason previous.drafts } }, Cmd.none )

        SiteSetupChanged field value ->
            ( { model | siteSetup = SiteSetup.change field value model.siteSetup }, Cmd.none )

        TaglinesLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.taglines
                in
                ( { model | taglines = { previous | items = Remote.fromResult (Api.decodeResponse (Domain.page Domain.tagline) response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        EmojiLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.customEmoji
                in
                ( { model | customEmoji = { previous | items = Remote.fromResult (Api.decodeResponse CustomEmoji.decoder response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        OAuthProvidersLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.oauthProviders
                in
                ( { model | oauthProviders = { previous | items = Remote.fromResult (Api.decodeResponse OAuthProviders.decoder response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        OAuthUsernameChanged value ->
            let
                previous =
                    model.oauthLogin
            in
            ( { model | oauthLogin = { previous | username = value } }, Cmd.none )

        OAuthAnswerChanged value ->
            let
                previous =
                    model.oauthLogin
            in
            ( { model | oauthLogin = { previous | answer = value } }, Cmd.none )

        OAuthTotpChanged value ->
            let
                previous =
                    model.oauthLogin
            in
            ( { model | oauthLogin = { previous | totp = value } }, Cmd.none )

        OAuthStart provider ->
            let
                previous =
                    model.oauthLogin
            in
            if not previous.starting && List.any (\item -> item.id == provider.id) previous.providers then
                ( { model | oauthLogin = { previous | starting = True, startFailed = False } }, OAuthLogin.start provider previous )

            else
                ( model, Cmd.none )

        OAuthSubmit ->
            case model.oauthLogin.callback of
                OAuthLogin.Ready callback ->
                    let
                        previous =
                            model.oauthLogin
                    in
                    ( { model | oauthLogin = { previous | callback = OAuthLogin.Submitting, totp = "" } }
                    , Api.send "" "POST" "/oauth/authenticate" (OAuthLogin.body callback previous.totp) (OAuthFinished model.routeEpoch)
                    )

                _ ->
                    ( model, Cmd.none )

        OAuthFinished epoch response ->
            if epoch == model.routeEpoch && model.route == Route.OAuthCallback then
                let
                    previous =
                        model.oauthLogin
                in
                case Api.decodeResponse Domain.loginResponse response of
                    Ok result ->
                        if result.registrationCreated then
                            ( { model | oauthLogin = { previous | callback = OAuthLogin.ApplicationSent } }, Cmd.none )

                        else if result.verifyEmailSent then
                            ( { model | oauthLogin = { previous | callback = OAuthLogin.VerificationSent } }, Cmd.none )

                        else if result.jwt /= Nothing then
                            ( model, Api.get "/account" (OAuthAccountLoaded epoch << Api.decodeResponse Domain.myUserInfo) )

                        else
                            ( { model | oauthLogin = { previous | callback = OAuthLogin.SessionFailed } }, Cmd.none )

                    Err problem ->
                        ( { model | oauthLogin = { previous | callback = OAuthLogin.Failed problem } }, Cmd.none )

            else
                ( model, Cmd.none )

        OAuthAccountLoaded epoch result ->
            if epoch == model.routeEpoch && model.route == Route.OAuthCallback then
                let
                    previous =
                        model.oauthLogin
                in
                case result of
                    Ok identity ->
                        let
                            changed =
                                { model
                                    | auth = Authenticated identity
                                    , authGeneration = model.authGeneration + 1
                                    , drawerProfile = Loading
                                    , oauthLogin = { previous | callback = OAuthLogin.NotStarted, username = "", answer = "", totp = "" }
                                }
                        in
                        ( changed
                        , Cmd.batch [ Navigation.replaceUrl model.key (Route.path Route.Home), unreadCommand changed, loadDrawerProfile changed, themeCommand changed ]
                        )

                    Err _ ->
                        ( { model | oauthLogin = { previous | callback = OAuthLogin.SessionFailed } }, Cmd.none )

            else
                ( model, Cmd.none )

        SiteUsersLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.siteUsers
                in
                ( { model | siteUsers = { previous | users = Remote.fromResult (Api.decodeResponse (Domain.page Domain.localUserView) response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        SiteMediaLoaded epoch response ->
            if epoch == model.routeEpoch then
                ( { model | siteMedia = Remote.fromResult (Api.decodeResponse SiteMedia.decoder response) }, Cmd.none )

            else
                ( model, Cmd.none )

        SiteConfigurationLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.siteConfiguration
                in
                case Api.decodeResponse SiteConfiguration.decoder response of
                    Ok snapshot ->
                        ( { model | siteConfiguration = { previous | snapshot = Ready snapshot, fields = snapshot.fields, flags = snapshot.flags, icon = snapshot.icon, banner = snapshot.banner, dirty = Set.empty, busy = False } }, Cmd.none )

                    Err problem ->
                        ( { model | siteConfiguration = { previous | snapshot = Failed problem, busy = False } }, Cmd.none )

            else
                ( model, Cmd.none )

        SiteConfigurationChanged key value ->
            ( { model | siteConfiguration = SiteConfiguration.change key value model.siteConfiguration }, Cmd.none )

        SiteConfigurationToggled key value ->
            ( { model | siteConfiguration = SiteConfiguration.toggle key value model.siteConfiguration }, Cmd.none )

        SiteConfigurationSave ->
            case model.auth of
                Authenticated account ->
                    if Domain.isAdmin account && not model.siteConfiguration.busy && SiteConfiguration.valid model.siteConfiguration && not (Set.isEmpty model.siteConfiguration.dirty) then
                        let
                            previous =
                                model.siteConfiguration
                        in
                        ( { model | siteConfiguration = { previous | busy = True, problem = Nothing } }, Api.send "" "PUT" "/site" (SiteConfiguration.body previous) (SiteConfigurationSaved model.routeEpoch) )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SiteConfigurationSaved epoch response ->
            if epoch /= model.routeEpoch then
                ( model, Cmd.none )

            else
                case Api.decodeUnit response of
                    Ok _ ->
                        ( model, Cmd.batch [ Api.get "/site" (SiteConfigurationLoaded epoch), Api.get "/site" (SiteLoaded << Api.decodeResponse Domain.getSiteResponse) ] )

                    Err problem ->
                        let
                            previous =
                                model.siteConfiguration
                        in
                        ( { model | siteConfiguration = { previous | busy = False, problem = Just problem } }, Cmd.none )

        SiteConfigurationImageSelected kind selected ->
            case ( model.auth, selected ) of
                ( Authenticated account, Just file ) ->
                    if Domain.isAdmin account && List.member kind [ "icon", "banner" ] && not model.siteConfiguration.imageBusy then
                        let
                            previous =
                                model.siteConfiguration
                        in
                        ( { model | siteConfiguration = { previous | imageBusy = True, problem = Nothing } }, Api.uploadTo ("/site/" ++ kind) file (SiteConfigurationImageFinished model.routeEpoch kind False) )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SiteConfigurationImageRemove kind ->
            if List.member kind [ "icon", "banner" ] then
                update (OpenConfirmation (RemoveSiteImageDialog kind)) model

            else
                ( model, Cmd.none )

        SiteConfigurationImageFinished epoch kind removed response ->
            if epoch /= model.routeEpoch then
                ( model, Cmd.none )

            else
                let
                    previous =
                        model.siteConfiguration

                    result =
                        if removed then
                            Api.decodeUnit response |> Result.map (\_ -> Nothing)

                        else
                            Api.decodeResponse Domain.imageUpload response |> Result.map (.imageUrl >> Just)
                in
                case result of
                    Ok url ->
                        ( { model
                            | siteConfiguration =
                                if kind == "icon" then
                                    { previous | icon = url, imageBusy = False }

                                else
                                    { previous | banner = url, imageBusy = False }
                          }
                        , Api.get "/site" (SiteLoaded << Api.decodeResponse Domain.getSiteResponse)
                        )

                    Err problem ->
                        ( { model | siteConfiguration = { previous | imageBusy = False, problem = Just problem } }, Cmd.none )

        FederationPolicyLoaded epoch response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.federationPolicy
                in
                ( { model | federationPolicy = { previous | items = Remote.fromResult (Api.decodeResponse FederationPolicy.decoder response) } }, Cmd.none )

            else
                ( model, Cmd.none )

        FederationPolicyChanged field value ->
            ( { model | federationPolicy = FederationPolicy.change field value model.federationPolicy }, Cmd.none )

        FederationPolicySubmit ->
            case model.auth of
                Authenticated account ->
                    if Domain.isAdmin account && model.route == Route.AdminFederation && not model.federationPolicy.busy && FederationPolicy.valid model.federationPolicy then
                        let
                            previous =
                                model.federationPolicy

                            ( path, body ) =
                                FederationPolicy.body previous
                        in
                        ( { model | federationPolicy = { previous | busy = True, problem = Nothing } }
                        , Api.send "" "POST" path body (FederationPolicySaved model.routeEpoch)
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        FederationPolicySaved epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeUnit response of
                    Ok _ ->
                        let
                            ( state, command ) =
                                FederationPolicy.load model.auth model.url (FederationPolicyLoaded epoch)
                        in
                        ( { model | federationPolicy = state }, command )

                    Err problem ->
                        let
                            previous =
                                model.federationPolicy
                        in
                        ( { model | federationPolicy = { previous | busy = False, problem = Just problem } }, Cmd.none )

            else
                ( model, Cmd.none )

        SiteAdminChanged epoch response ->
            if epoch == model.routeEpoch then
                let
                    ( state, command ) =
                        SiteUsers.load model.auth model.url (SiteUsersLoaded epoch)

                    problem =
                        case Api.decodeUnit response of
                            Ok _ ->
                                Nothing

                            Err failure ->
                                Just failure
                in
                ( { model | siteUsers = { state | problem = problem } }, command )

            else
                ( model, Cmd.none )

        OAuthProviderFieldChanged key value ->
            let
                previous =
                    model.oauthProviders

                current =
                    previous.form
            in
            ( { model | oauthProviders = { previous | form = { current | fields = Dict.insert key value current.fields } } }, Cmd.none )

        OAuthProviderFlagChanged key value ->
            let
                previous =
                    model.oauthProviders

                current =
                    previous.form
            in
            ( { model | oauthProviders = { previous | form = { current | flags = Dict.insert key value current.flags } } }, Cmd.none )

        OAuthProviderEdit provider ->
            let
                previous =
                    model.oauthProviders
            in
            ( { model | oauthProviders = { previous | form = { id = Just provider.id, fields = provider.fields, flags = provider.flags }, problem = Nothing } }, focus "provider-display_name" )

        OAuthProviderCancel ->
            let
                previous =
                    model.oauthProviders
            in
            ( { model | oauthProviders = { previous | form = OAuthProviders.emptyForm, problem = Nothing } }, Cmd.none )

        OAuthProviderSubmit ->
            if OAuthProviders.valid model.oauthProviders.form then
                oauthProviderRequest
                    (if model.oauthProviders.form.id == Nothing then
                        "POST"

                     else
                        "PUT"
                    )
                    (OAuthProviders.body model.oauthProviders.form)
                    model

            else
                ( model, Cmd.none )

        OAuthProviderSaved epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeUnit response of
                    Ok _ ->
                        let
                            ( state, command ) =
                                OAuthProviders.load model.auth (OAuthProvidersLoaded epoch)
                        in
                        ( { model | oauthProviders = state }, command )

                    Err problem ->
                        let
                            previous =
                                model.oauthProviders
                        in
                        ( { model | oauthProviders = { previous | busy = False, problem = Just problem } }, Cmd.none )

            else
                ( model, Cmd.none )

        EmojiChanged field value ->
            let
                previous =
                    model.customEmoji
            in
            ( { model | customEmoji = { previous | form = CustomEmoji.change field value previous.form } }, Cmd.none )

        EmojiEdit emoji ->
            let
                previous =
                    model.customEmoji

                current =
                    { id = Just emoji.id
                    , shortcode = emoji.shortcode
                    , imageUrl = emoji.imageUrl
                    , altText = emoji.altText
                    , category = emoji.category
                    , keywords = String.join ", " emoji.keywords
                    }
            in
            ( { model | customEmoji = { previous | form = current, problem = Nothing } }, focus "emoji-shortcode" )

        EmojiCancel ->
            let
                previous =
                    model.customEmoji
            in
            ( { model | customEmoji = { previous | form = CustomEmoji.emptyForm, problem = Nothing } }, Cmd.none )

        EmojiSubmit ->
            if CustomEmoji.valid model.customEmoji.form then
                emojiRequest
                    (if model.customEmoji.form.id == Nothing then
                        "POST"

                     else
                        "PUT"
                    )
                    (CustomEmoji.body model.customEmoji.form)
                    model

            else
                ( model, Cmd.none )

        EmojiSaved epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeUnit response of
                    Ok _ ->
                        let
                            ( state, command ) =
                                CustomEmoji.load model.auth (EmojiLoaded epoch)
                        in
                        ( { model | customEmoji = state }, command )

                    Err problem ->
                        let
                            previous =
                                model.customEmoji
                        in
                        ( { model | customEmoji = { previous | busy = False, problem = Just problem } }, Cmd.none )

            else
                ( model, Cmd.none )

        TaglineNewChanged value ->
            let
                previous =
                    model.taglines
            in
            ( { model | taglines = { previous | newContent = value } }, Cmd.none )

        TaglineEditChanged id value ->
            let
                previous =
                    model.taglines
            in
            ( { model | taglines = { previous | edits = Dict.insert id value previous.edits } }, Cmd.none )

        TaglineSave maybeId ->
            let
                previous =
                    model.taglines

                content =
                    case maybeId of
                        Nothing ->
                            previous.newContent

                        Just id ->
                            Dict.get id previous.edits
                                |> Maybe.withDefault
                                    (case previous.items of
                                        Ready results ->
                                            results.items |> List.filter (\item -> item.id == id) |> List.head |> Maybe.map .content |> Maybe.withDefault ""

                                        _ ->
                                            ""
                                    )

                fields =
                    ( "content", Encode.string content )
                        :: (case maybeId of
                                Nothing ->
                                    []

                                Just id ->
                                    [ ( "id", Encode.int id ) ]
                           )
            in
            if not (String.isEmpty (String.trim content)) then
                taglineRequest
                    (if maybeId == Nothing then
                        "POST"

                     else
                        "PUT"
                    )
                    fields
                    model

            else
                ( model, Cmd.none )

        TaglineSaved epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeUnit response of
                    Ok _ ->
                        let
                            ( state, command ) =
                                Taglines.load model.auth model.url (TaglinesLoaded epoch)
                        in
                        ( { model | taglines = state }, command )

                    Err problem ->
                        let
                            previous =
                                model.taglines
                        in
                        ( { model | taglines = { previous | busy = False, problem = Just problem } }, Cmd.none )

            else
                ( model, Cmd.none )

        SiteSetupSubmitted ->
            case ( model.auth, model.site ) of
                ( Authenticated identity, Just site ) ->
                    if Domain.isAdmin identity && not site.localSite.siteSetup && not model.siteSetup.submitting && not (String.isEmpty (String.trim model.siteSetup.name)) then
                        let
                            previous =
                                model.siteSetup
                        in
                        ( { model | siteSetup = { previous | submitting = True, problem = Nothing } }
                        , Api.send "" "POST" "/site" (SiteSetup.body previous) (SiteSetupFinished model.routeEpoch)
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SiteSetupFinished epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeUnit response of
                    Ok _ ->
                        ( { model | siteSetup = SiteSetup.initial }
                        , Cmd.batch
                            [ Api.get "/site" (SiteLoaded << Api.decodeResponse Domain.getSiteResponse)
                            , Navigation.replaceUrl model.key (Route.path Route.Home)
                            ]
                        )

                    Err problem ->
                        let
                            previous =
                                model.siteSetup
                        in
                        ( { model | siteSetup = { previous | submitting = False, problem = Just problem } }, Cmd.none )

            else
                ( model, Cmd.none )

        RegistrationDecision id approve ->
            if RegistrationApplications.allowed model.auth && not model.registrationApplications.submitting then
                let
                    previous =
                        model.registrationApplications

                    reason =
                        Dict.get id previous.drafts |> Maybe.withDefault "" |> String.trim

                    body =
                        Encode.object
                            ([ ( "id", Encode.int id ), ( "approve", Encode.bool approve ) ]
                                ++ (if not approve && not (String.isEmpty reason) then
                                        [ ( "deny_reason", Encode.string reason ) ]

                                    else
                                        []
                                   )
                            )
                in
                ( { model | registrationApplications = { previous | submitting = True, problem = Nothing } }
                , Api.send "" "PUT" "/admin/registration_application/approve" (Encode.encode 0 body) (RegistrationDecided model.routeEpoch id)
                )

            else
                ( model, Cmd.none )

        RegistrationDecided epoch id response ->
            if epoch == model.routeEpoch then
                let
                    previous =
                        model.registrationApplications

                    ( state, command ) =
                        RegistrationApplications.load model.auth model.url (RegistrationApplicationsLoaded epoch)

                    outcome =
                        Api.decodeUnit response
                in
                ( { model
                    | registrationApplications =
                        { state
                            | drafts =
                                case outcome of
                                    Ok _ ->
                                        Dict.remove id previous.drafts

                                    Err _ ->
                                        previous.drafts
                            , problem =
                                case outcome of
                                    Ok _ ->
                                        Nothing

                                    Err problem ->
                                        Just problem
                        }
                  }
                , command
                )

            else
                ( model, Cmd.none )

        PendingFollowDecision communityId followerId approve ->
            if PendingFollows.allowed model.auth && not model.pendingFollows.submitting then
                let
                    previous =
                        model.pendingFollows

                    body =
                        Encode.object
                            [ ( "community_id", Encode.int communityId )
                            , ( "follower_id", Encode.int followerId )
                            , ( "approve", Encode.bool approve )
                            ]
                in
                ( { model | pendingFollows = { previous | submitting = True, problem = Nothing } }
                , Api.send "" "POST" "/community/pending_follows/approve" (Encode.encode 0 body) (PendingFollowDecided model.routeEpoch)
                )

            else
                ( model, Cmd.none )

        PendingFollowDecided epoch response ->
            if epoch == model.routeEpoch then
                let
                    ( state, command ) =
                        PendingFollows.load model.auth model.url (PendingFollowsLoaded epoch)

                    problem =
                        case Api.decodeUnit response of
                            Ok _ ->
                                Nothing

                            Err failure ->
                                Just failure
                in
                ( { model | pendingFollows = { state | problem = problem } }, command )

            else
                ( model, Cmd.none )

        ExternalInteractionLoaded epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeResponse ExternalInteraction.decoder response of
                    Ok route ->
                        ( { model | externalInteraction = Ready () }, Navigation.replaceUrl model.key (Route.path route) )

                    Err problem ->
                        ( { model | externalInteraction = Failed problem }, Cmd.none )

            else
                ( model, Cmd.none )

        SearchResponse epoch event ->
            if epoch == model.routeEpoch then
                updateSearch event model

            else
                ( model, Cmd.none )

        NotificationsMessage event ->
            updateNotifications event model

        NotificationsResponse epoch event ->
            if epoch == model.routeEpoch then
                updateNotifications event model

            else
                ( model, Cmd.none )

        MultiCommunityMessage event ->
            updateMultiCommunity event model

        MultiCommunityResponse epoch event ->
            if epoch == model.routeEpoch then
                updateMultiCommunity event model

            else
                ( model, Cmd.none )

        CommunityCreateMessage event ->
            updateCommunityCreate event model

        CommunityCreateResponse epoch event ->
            if epoch == model.routeEpoch then
                updateCommunityCreate event model

            else
                ( model, Cmd.none )

        PostMessage event ->
            updatePost event model

        PostResponse epoch event ->
            if epoch == model.routeEpoch then
                updatePost event model

            else
                ( model, Cmd.none )

        CommentTargetLoaded epoch response ->
            if epoch == model.routeEpoch then
                case Api.decodeResponse (Decode.field "comment_view" Domain.commentView) response of
                    Ok comment ->
                        if comment.comment.deleted || comment.post.deleted || comment.post.removed then
                            ( { model | commentTarget = Failed { status = 404, detail = "unavailable" } }, focus "comment-target-error" )

                        else
                            ( { model | commentTarget = Ready () }
                            , Navigation.replaceUrl model.key (Route.path (Route.Post comment.post.id (Just comment.comment.id)))
                            )

                    Err problem ->
                        let
                            base =
                                authProblem model problem
                        in
                        ( { base | commentTarget = Failed problem }, focus "comment-target-error" )

            else
                ( model, Cmd.none )

        FeedResponse epoch event ->
            if epoch == model.routeEpoch then
                updateFeed event model

            else
                ( model, Cmd.none )

        CommunityMessage event ->
            updateCommunity event model

        CommunityResponse epoch event ->
            if epoch == model.routeEpoch then
                updateCommunity event model

            else
                ( model, Cmd.none )

        DismissFlash ->
            ( { model | flash = NoFlash }, Cmd.none )

        DismissDonation ->
            ( { model | donationPrompt = False }
            , Api.send "" "POST" "/account/donation_dialog_shown" "" (\_ -> Noop)
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    incoming Incoming


loadDrawerProfile : Model -> Cmd Msg
loadDrawerProfile model =
    case model.auth of
        Authenticated _ ->
            Api.get "/account" (DrawerProfileLoaded << Api.decodeResponse Domain.ownPersonView)

        _ ->
            Cmd.none


themeCommand : Model -> Cmd Msg
themeCommand model =
    case model.auth of
        Authenticated account ->
            setTheme account.localUserView.localUser.theme

        _ ->
            Cmd.none


confirmAction : ConfirmationAction -> Model -> ( Model, Cmd Msg )
confirmAction action model =
    case action of
        DeletePostDialog id ->
            updatePost (Post.ConfirmDelete id) model

        ResolveReportDialog id stateValue ->
            case model.route of
                Route.Reports ->
                    updateSiteAdmin (SiteAdmin.ResolveReport id stateValue) model

                Route.CommunitySettings _ ->
                    updateManage (Manage.ManageResolveReport id stateValue) model

                _ ->
                    ( model, Cmd.none )

        RemoveSiteBanDialog ->
            updateSiteAdmin SiteAdmin.RemoveBan model

        RemoveCommunityBanDialog ->
            updateManage Manage.ManageRemoveBan model

        RemoveBlockDialog kind target ->
            updateAccountBlocks (AccountBlocks.RemoveBlock kind target) model

        SetMultiCommunityDeletedDialog deleted ->
            updateMultiCommunity (MultiCommunity.SetDeleted deleted) model

        DeleteTaglineDialog id _ ->
            taglineRequest "DELETE" [ ( "id", Encode.int id ) ] model

        DeleteEmojiDialog id _ ->
            emojiRequest "DELETE" (Encode.encode 0 (Encode.object [ ( "id", Encode.int id ) ])) model

        DeleteOAuthProviderDialog id _ ->
            oauthProviderRequest "DELETE" (Encode.encode 0 (Encode.object [ ( "id", Encode.int id ) ])) model

        ChangeSiteAdminDialog id _ added ->
            case model.auth of
                Authenticated user ->
                    if Domain.isAdmin user && id /= user.localUserView.person.id && model.route == Route.AdminUsers && not model.siteUsers.busy then
                        let
                            previous =
                                model.siteUsers

                            body =
                                Encode.object [ ( "person_id", Encode.int id ), ( "added", Encode.bool added ) ]
                        in
                        ( { model | siteUsers = { previous | busy = True, problem = Nothing } }
                        , Api.send "" "POST" "/admin/add" (Encode.encode 0 body) (SiteAdminChanged model.routeEpoch)
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RemoveSiteImageDialog kind ->
            case model.auth of
                Authenticated account ->
                    if Domain.isAdmin account && model.route == Route.AdminConfiguration && List.member kind [ "icon", "banner" ] && not model.siteConfiguration.imageBusy then
                        let
                            previous =
                                model.siteConfiguration
                        in
                        ( { model | siteConfiguration = { previous | imageBusy = True, problem = Nothing } }, Api.send "" "DELETE" ("/site/" ++ kind) "" (SiteConfigurationImageFinished model.routeEpoch kind True) )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


confirmationTriggerId : ConfirmationAction -> String
confirmationTriggerId action =
    case action of
        DeletePostDialog id ->
            deleteTriggerId id

        ResolveReportDialog id _ ->
            "resolve-report-" ++ id

        RemoveSiteBanDialog ->
            "site-ban-remove"

        RemoveCommunityBanDialog ->
            "community-ban-remove"

        RemoveBlockDialog kind target ->
            "block-remove-" ++ kind ++ "-" ++ target

        SetMultiCommunityDeletedDialog _ ->
            "multi-community-delete"

        DeleteTaglineDialog id _ ->
            "tagline-delete-" ++ String.fromInt id

        DeleteEmojiDialog id _ ->
            "emoji-delete-" ++ String.fromInt id

        DeleteOAuthProviderDialog id _ ->
            "provider-delete-" ++ String.fromInt id

        ChangeSiteAdminDialog id _ _ ->
            "site-admin-" ++ String.fromInt id

        RemoveSiteImageDialog kind ->
            "site-remove-" ++ kind


oauthProviderRequest : String -> String -> Model -> ( Model, Cmd Msg )
oauthProviderRequest method body model =
    case model.auth of
        Authenticated account ->
            if Domain.isAdmin account && model.route == Route.AdminOAuthProviders && not model.oauthProviders.busy then
                let
                    previous =
                        model.oauthProviders
                in
                ( { model | oauthProviders = { previous | busy = True, problem = Nothing } }
                , Api.send "" method "/oauth_provider" body (OAuthProviderSaved model.routeEpoch)
                )

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


emojiRequest : String -> String -> Model -> ( Model, Cmd Msg )
emojiRequest method body model =
    case model.auth of
        Authenticated account ->
            if Domain.isAdmin account && model.route == Route.AdminEmoji && not model.customEmoji.busy then
                let
                    previous =
                        model.customEmoji
                in
                ( { model | customEmoji = { previous | busy = True, problem = Nothing } }
                , Api.send "" method "/custom_emoji" body (EmojiSaved model.routeEpoch)
                )

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


taglineRequest : String -> List ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
taglineRequest method fields model =
    case model.auth of
        Authenticated account ->
            if Domain.isAdmin account && model.route == Route.AdminTaglines && not model.taglines.busy then
                let
                    previous =
                        model.taglines
                in
                ( { model | taglines = { previous | busy = True, problem = Nothing } }
                , Api.send "" method "/admin/tagline" (Encode.encode 0 (Encode.object fields)) (TaglineSaved model.routeEpoch)
                )

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
