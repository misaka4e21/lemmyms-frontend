module App.View exposing (view)

import AccountSource exposing (AccountContentSource(..))
import App.Context exposing (Active)
import App.Shell exposing (viewBoot, viewReady)
import App.State exposing (ConfirmationAction(..), Model, Msg(..))
import App.View.Account exposing (pageLogin, pagePasswordReset, pagePasswordResetConfirm, pagePasswordSettings, pagePublicProfile, pageRegister, pageSettings, pageVerify)
import App.View.Content exposing (editorConfig, pageCommentTarget, pageCommunities, pageCommunity, pageCreatePost, pageLatest, pagePost, pageSearch, postCard)
import App.View.Participation exposing (pageManage, pageMessageComposer, pageNewCommunity, pageNotifications)
import Browser
import Dict
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.CustomEmoji as CustomEmoji
import Feature.Editor.State exposing (EditorMode(..))
import Feature.Editor.Update as Editor
import Feature.Editor.View
import Feature.FederationPolicy as FederationPolicy
import Feature.Instances as Instances
import Feature.MultiCommunity as MultiCommunity
import Feature.OAuthLogin as OAuthLogin
import Feature.OAuthProviders as OAuthProviders
import Feature.PendingFollows as PendingFollows
import Feature.RegistrationApplications as RegistrationApplications
import Feature.Report as Report
import Feature.SiteAdmin.Update as SiteAdmin
import Feature.SiteAdmin.View as SiteAdminView
import Feature.SiteConfiguration as SiteConfiguration
import Feature.SiteMedia as SiteMedia
import Feature.SiteSetup as SiteSetup
import Feature.SiteUsers as SiteUsers
import Feature.Taglines as Taglines
import Generated.I18n as Translations
import Html exposing (Html, p, text)
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)


view : Model -> Browser.Document Msg
view model =
    let
        title =
            case model.active of
                Nothing ->
                    "Commune"

                Just active ->
                    let
                        appName =
                            Translations.appTitle active.texts

                        pageName =
                            routeTitle model active
                    in
                    if String.isEmpty appName then
                        pageName

                    else if String.isEmpty pageName || pageName == appName then
                        appName

                    else
                        pageName ++ " · " ++ appName
    in
    { title = title
    , body =
        [ case model.active of
            Nothing ->
                viewBoot model

            Just active ->
                viewReady (pageView model active) (reportDialog model active) model active
        ]
    }


routeTitle : Model -> Active -> String
routeTitle model active =
    let
        texts =
            active.texts
    in
    case model.route of
        Route.Home ->
            Translations.latestTitle texts

        Route.Communities ->
            Translations.communitiesTitle texts

        Route.Community _ ->
            case model.communityPage.community of
                Ready community ->
                    Maybe.withDefault community.community.name community.community.title

                _ ->
                    Translations.communitiesTitle texts

        Route.Post _ _ ->
            case model.posts.post of
                Ready post ->
                    if String.isEmpty post.post.name then
                        Translations.repliesTitle texts

                    else
                        post.post.name

                _ ->
                    Translations.repliesTitle texts

        Route.Comment _ ->
            Translations.repliesTitle texts

        Route.EditComment _ ->
            Translations.editComment texts

        Route.CreateCommunity ->
            Translations.createCommunity texts

        Route.CreatePrivateMessage _ ->
            Translations.createPrivateMessage texts

        Route.MultiCommunities ->
            Translations.multiCommunities texts

        Route.CreateMultiCommunity ->
            Translations.createMultiCommunity texts

        Route.MultiCommunity _ ->
            Translations.multiCommunities texts

        Route.MultiCommunitySettings _ ->
            Translations.multiCommunitySettings texts

        Route.CreatePost _ ->
            Translations.publishTopic texts

        Route.EditPost _ ->
            Translations.editPost texts

        Route.Login ->
            Translations.loginTitle texts

        Route.Register ->
            Translations.registerTitle texts

        Route.VerifyEmail _ ->
            Translations.verifyTitle texts

        Route.Search ->
            Translations.searchTitle texts

        Route.Notifications ->
            Translations.notificationsTitle texts

        Route.Profile _ ->
            Translations.profileTitle texts

        Route.Settings ->
            Translations.settingsTitle texts

        Route.LoginReset ->
            Translations.resetPasswordTitle texts

        Route.PasswordChange _ ->
            Translations.resetPasswordTitle texts

        Route.PasswordSettings ->
            Translations.changePasswordTitle texts

        Route.AccountContent source ->
            accountContentTitle texts source

        Route.AccountBlocks ->
            Translations.blockTitle texts

        Route.Admin ->
            Translations.adminTitle texts

        Route.Reports ->
            Translations.reportsTitle texts

        Route.Modlog _ ->
            Translations.modlogTitle texts

        Route.AdminBans ->
            Translations.banTitle texts

        Route.AdminSettings ->
            Translations.voteSettingsTitle texts

        Route.Legal ->
            Translations.legalInformation texts

        Route.Instances ->
            Instances.title active.texts

        Route.ExternalInteraction ->
            Translations.resolvedResult texts

        Route.PendingFollows ->
            Translations.followRequests texts

        Route.RegistrationApplications ->
            RegistrationApplications.title texts

        Route.Setup ->
            Translations.siteSetup texts

        Route.AdminTaglines ->
            Translations.taglines texts

        Route.AdminEmoji ->
            Translations.customEmojis texts

        Route.AdminOAuthProviders ->
            Translations.oauthProviders texts

        Route.AdminUsers ->
            Translations.siteUsers texts

        Route.AdminMedia ->
            Translations.siteMedia texts

        Route.AdminConfiguration ->
            Translations.siteConfiguration texts

        Route.AdminFederation ->
            Translations.federationPolicy texts

        Route.OAuthCallback ->
            Translations.oauthCallback texts

        Route.CommunitySettings _ ->
            Translations.manageTitle texts

        Route.NotFound ->
            Translations.notFound texts


pageView : Model -> Active -> Html Msg
pageView model active =
    case model.route of
        Route.OAuthCallback ->
            OAuthLogin.callbackPage { totp = OAuthTotpChanged, submit = OAuthSubmit } active model.oauthLogin

        Route.AdminFederation ->
            FederationPolicy.page
                { retry = RetryPage, changed = FederationPolicyChanged, submit = FederationPolicySubmit }
                active
                model.auth
                model.url
                model.federationPolicy

        Route.AdminMedia ->
            SiteMedia.page RetryPage active model.auth model.url model.siteMedia

        Route.AdminConfiguration ->
            SiteConfiguration.page
                { retry = RetryPage
                , changed = SiteConfigurationChanged
                , toggled = SiteConfigurationToggled
                , save = SiteConfigurationSave
                , imageSelected = SiteConfigurationImageSelected
                , imageRemove = SiteConfigurationImageRemove
                }
                active
                model.auth
                model.siteConfiguration

        Route.AdminUsers ->
            SiteUsers.page
                { retry = RetryPage, changeAdmin = \id name added -> OpenConfirmation (ChangeSiteAdminDialog id name added) }
                active
                model.auth
                model.url
                model.siteUsers

        Route.AdminOAuthProviders ->
            OAuthProviders.page
                { retry = RetryPage
                , changed = OAuthProviderFieldChanged
                , flagChanged = OAuthProviderFlagChanged
                , edit = OAuthProviderEdit
                , cancel = OAuthProviderCancel
                , submit = OAuthProviderSubmit
                , delete = \provider -> OpenConfirmation (DeleteOAuthProviderDialog provider.id (Dict.get "display_name" provider.fields |> Maybe.withDefault ""))
                }
                active
                model.auth
                model.oauthProviders

        Route.AdminEmoji ->
            CustomEmoji.page
                { retry = RetryPage
                , changed = EmojiChanged
                , edit = EmojiEdit
                , cancel = EmojiCancel
                , submit = EmojiSubmit
                , delete = \emoji -> OpenConfirmation (DeleteEmojiDialog emoji.id emoji.shortcode)
                }
                active
                model.auth
                model.customEmoji

        Route.AdminTaglines ->
            Taglines.page
                { retry = RetryPage
                , newChanged = TaglineNewChanged
                , editChanged = TaglineEditChanged
                , create = TaglineSave Nothing
                , save = Just >> TaglineSave
                , delete = \id content -> OpenConfirmation (DeleteTaglineDialog id content)
                }
                active
                model.auth
                model.url
                model.taglines

        Route.Setup ->
            SiteSetup.page { change = SiteSetupChanged, submit = SiteSetupSubmitted } active model.auth model.site model.siteSetup

        Route.RegistrationApplications ->
            RegistrationApplications.page
                { retry = RetryPage, changeReason = RegistrationReasonChanged, decide = RegistrationDecision }
                active
                model.auth
                model.url
                model.registrationApplications

        Route.PendingFollows ->
            PendingFollows.page { retry = RetryPage, decide = PendingFollowDecision } active model.auth model.url model.pendingFollows

        Route.ExternalInteraction ->
            pageHeading (Translations.resolvedResult active.texts)
                (viewRemote RetryPage active.texts model.externalInteraction (\_ -> text ""))

        Route.Instances ->
            Instances.page RetryPage active model.url model.instances

        Route.Legal ->
            pageHeading (Translations.legalInformation active.texts)
                (case model.site |> Maybe.andThen (.localSite >> .legalInformation) of
                    Just legal ->
                        if String.isEmpty (String.trim legal) then
                            p [] [ text (Translations.noContent active.texts) ]

                        else
                            Markdown.render legal

                    Nothing ->
                        p [] [ text (Translations.noContent active.texts) ]
                )

        Route.Home ->
            pageLatest model active

        Route.Communities ->
            pageCommunities model active

        Route.Community name ->
            pageCommunity model active name

        Route.Post id _ ->
            pagePost model active (String.fromInt id)

        Route.Comment _ ->
            pageCommentTarget model active

        Route.EditComment id ->
            Feature.Editor.View.pageEditor (editorConfig model) { editor = model.editorPage.editor, source = model.editorPage.source } active (EditComment (String.fromInt id))

        Route.CreateCommunity ->
            pageNewCommunity model active

        Route.CreatePrivateMessage _ ->
            pageMessageComposer model active

        Route.MultiCommunities ->
            MultiCommunity.pageDirectory (multiCommunityConfig model active) model.multiCommunity (multiCommunityViewModel model) active

        Route.MultiCommunity name ->
            MultiCommunity.pageDetail (multiCommunityConfig model active) model.multiCommunity (multiCommunityViewModel model) active name

        Route.CreateMultiCommunity ->
            MultiCommunity.pageCreate (multiCommunityConfig model active) model.multiCommunity (multiCommunityViewModel model) active

        Route.MultiCommunitySettings name ->
            MultiCommunity.pageSettings (multiCommunityConfig model active) model.multiCommunity (multiCommunityViewModel model) active name

        Route.CreatePost (Just id) ->
            Feature.Editor.View.pageEditor (editorConfig model) { editor = model.editorPage.editor, source = model.editorPage.source } active (CreateTopic (String.fromInt id))

        Route.CreatePost Nothing ->
            pageCreatePost model active

        Route.EditPost id ->
            Feature.Editor.View.pageEditor (editorConfig model) { editor = model.editorPage.editor, source = model.editorPage.source } active (EditPost (String.fromInt id))

        Route.Login ->
            pageLogin model active

        Route.Register ->
            pageRegister model active

        Route.VerifyEmail _ ->
            pageVerify model active

        Route.Search ->
            pageSearch model active

        Route.Notifications ->
            pageNotifications model active

        Route.Profile username ->
            pagePublicProfile (postCard model active) model active username

        Route.Settings ->
            pageSettings model active

        Route.LoginReset ->
            pagePasswordReset model active

        Route.PasswordChange _ ->
            pagePasswordResetConfirm model active

        Route.PasswordSettings ->
            pagePasswordSettings model active

        Route.AccountContent source ->
            AccountContent.pageAccountContent
                { retry = RetryPage, postCard = postCard model active }
                { posts = model.accountContent.posts, auth = model.auth, url = model.url }
                active
                source

        Route.AccountBlocks ->
            AccountBlocks.pageAccountBlocks
                (accountBlocksConfig model)
                { blocks = model.accountBlocks.blocks
                , kind = model.accountBlocks.kind
                , target = model.accountBlocks.target
                , busy = model.accountBlocks.busy
                , problem = model.accountBlocks.problem
                , auth = model.auth
                }
                active

        Route.Admin ->
            SiteAdminView.pageOverview (siteAdminConfig model) (siteAdminViewModel model) active

        Route.Reports ->
            SiteAdminView.pageReports (siteAdminConfig model) (siteAdminViewModel model) active

        Route.Modlog _ ->
            SiteAdminView.pageModlog (siteAdminConfig model) (siteAdminViewModel model) active

        Route.AdminBans ->
            SiteAdminView.pageBans (siteAdminConfig model) (siteAdminViewModel model) active

        Route.AdminSettings ->
            SiteAdminView.pageSettings (siteAdminConfig model) (siteAdminViewModel model) active

        Route.CommunitySettings name ->
            pageManage model active name

        Route.NotFound ->
            pageHeading (Translations.notFound active.texts)
                (p [] [ text (Translations.notFound active.texts) ])


accountContentTitle : Translations.I18n -> AccountContentSource -> String
accountContentTitle texts source =
    case source of
        SavedContent ->
            Translations.savedPostsTitle texts

        ReadContent ->
            Translations.readPostsTitle texts

        HiddenContent ->
            Translations.hiddenPostsTitle texts

        LikedContent ->
            Translations.likedPostsTitle texts


accountBlocksConfig : Model -> AccountBlocks.Config Msg
accountBlocksConfig model =
    { retry = RetryPage
    , kindChanged = AccountBlocksMessage << AccountBlocks.KindChanged
    , targetChanged = AccountBlocksMessage << AccountBlocks.TargetChanged
    , addBlock = AccountBlocksMessage AccountBlocks.AddBlock
    , confirmRemoveBlock = \kind target -> OpenConfirmation (RemoveBlockDialog kind target)
    , formatted = model.formatted
    }


siteAdminConfig : Model -> SiteAdminView.Config Msg
siteAdminConfig _ =
    { retry = RetryPage
    , upvotesChanged = SiteAdminMessage << SiteAdmin.UpvotesChanged
    , downvotesChanged = SiteAdminMessage << SiteAdmin.DownvotesChanged
    , saveSettings = SiteAdminMessage SiteAdmin.SaveSettings
    , reportStateChanged = SiteAdminMessage << SiteAdmin.ReportStateChanged
    , reportCommunityChanged = SiteAdminMessage << SiteAdmin.ReportCommunityChanged
    , applyReportFilter = SiteAdminMessage SiteAdmin.ApplyReportFilter
    , reportNoteChanged = \id value -> SiteAdminMessage (SiteAdmin.ReportNoteChanged id value)
    , confirmResolveReport = \id state -> OpenConfirmation (ResolveReportDialog id state)
    , modlogCommunityChanged = SiteAdminMessage << SiteAdmin.ModlogCommunityChanged
    , applyModlogFilter = SiteAdminMessage SiteAdmin.ApplyModlogFilter
    , banActorChanged = SiteAdminMessage << SiteAdmin.BanActorChanged
    , banReasonChanged = SiteAdminMessage << SiteAdmin.BanReasonChanged
    , banExpiresChanged = SiteAdminMessage << SiteAdmin.BanExpiresChanged
    , createBan = SiteAdminMessage SiteAdmin.CreateBan
    , confirmRemoveBan = OpenConfirmation RemoveSiteBanDialog
    }


siteAdminViewModel : Model -> SiteAdminView.ViewModel
siteAdminViewModel model =
    { admin = model.siteAdmin
    , auth = model.auth
    , formatted = model.formatted
    , url = model.url
    }


multiCommunityConfig : Model -> Active -> MultiCommunity.Config Msg
multiCommunityConfig model active =
    { retry = RetryPage
    , listingChanged = MultiCommunityMessage << MultiCommunity.ListingChanged
    , sortChanged = MultiCommunityMessage << MultiCommunity.SortChanged
    , searchChanged = MultiCommunityMessage << MultiCommunity.SearchChanged
    , searchSubmitted = MultiCommunityMessage MultiCommunity.SearchSubmitted
    , postSortChanged = MultiCommunityMessage << MultiCommunity.PostSortChanged
    , timeRangeChanged = MultiCommunityMessage << MultiCommunity.TimeRangeChanged
    , follow = MultiCommunityMessage << MultiCommunity.Follow
    , nameChanged = MultiCommunityMessage << MultiCommunity.NameChanged
    , titleChanged = MultiCommunityMessage << MultiCommunity.TitleChanged
    , summaryChanged = MultiCommunityMessage << MultiCommunity.SummaryChanged
    , sidebarAuthoring = MultiCommunityMessage << MultiCommunity.SidebarAuthoring
    , save = MultiCommunityMessage MultiCommunity.Save
    , setDeleted = \deleted -> OpenConfirmation (SetMultiCommunityDeletedDialog deleted)
    , entrySearchChanged = MultiCommunityMessage << MultiCommunity.EntrySearchChanged
    , entrySearchSubmitted = MultiCommunityMessage MultiCommunity.EntrySearchSubmitted
    , addEntry = MultiCommunityMessage << MultiCommunity.AddEntry
    , removeEntry = MultiCommunityMessage << MultiCommunity.RemoveEntry
    , postCard = postCard model active
    }


multiCommunityViewModel : Model -> MultiCommunity.ViewModel
multiCommunityViewModel model =
    { auth = model.auth, url = model.url }


reportDialog : Model -> Active -> Html Msg
reportDialog model active =
    Report.reportDialog
        { close = ReportMessage Report.Close
        , reasonChanged = ReportMessage << Report.ReasonChanged
        , submit = ReportMessage Report.Submit
        }
        model.report
        active
