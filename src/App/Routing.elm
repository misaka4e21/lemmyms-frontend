module App.Routing exposing (loadRoute, loadSession, unreadCommand)

import Api
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.AccountSettings as AccountSettings
import Feature.Auth.State as AuthState
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State as ManageState
import Feature.CommunityManage.Update as Manage
import Feature.Editor.State as EditorState exposing (EditorMode(..), emptyEditor)
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Report as Report
import Feature.Search as Search
import Feature.SiteAdmin.State as SiteAdminState
import Feature.SiteAdmin.Update as SiteAdmin
import Json.Decode as Decode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Url exposing (Url)


loadRoute : Model -> ( Model, Cmd Msg )
loadRoute model =
    let
        reset =
            { model
                | feed = Feed.initial
                , communityPage = Community.initial
                , posts = Post.reset model.posts
                , profile = Profile.reset model.profile
                , notificationsPage = Notifications.initial
                , editorPage = EditorState.initial
                , management = ManageState.reset model.management
                , accountContent = AccountContent.reset model.accountContent
                , accountSettings = AccountSettings.initial
                , accountBlocks = AccountBlocks.reset model.accountBlocks
                , report = Report.initial
                , siteAdmin = SiteAdminState.reset model.siteAdmin
                , commentTarget = NotAsked
            }

        epoch =
            model.routeEpoch
    in
    case model.route of
        Route.Home ->
            let
                ( state, command ) =
                    Feed.load model.url
            in
            ( { reset | feed = state }, Cmd.map (FeedResponse epoch) command )

        Route.Communities ->
            loadCommunity reset

        Route.Community _ ->
            loadCommunity reset

        Route.Post id commentId ->
            let
                ( state, command ) =
                    Post.load id commentId model.url reset.posts
            in
            ( { reset | posts = state }, Cmd.map (PostResponse epoch) command )

        Route.Comment commentId ->
            ( { reset | commentTarget = Loading }
            , Api.get ("/comment?id=" ++ String.fromInt commentId) (CommentTargetLoaded model.routeEpoch)
            )

        Route.CreateCommunity ->
            ( { reset | communityCreate = CommunityCreate.initial }, Cmd.none )

        Route.CreatePost (Just id) ->
            loadCommunity { reset | editorPage = { editor = Just (emptyEditor (CreateTopic (String.fromInt id))), source = NotAsked } }

        Route.CreatePost Nothing ->
            ( reset, Cmd.none )

        Route.EditPost id ->
            let
                ( state, command ) =
                    Editor.load (String.fromInt id) reset.editorPage
            in
            ( { reset | editorPage = state }, Cmd.map (EditorResponse epoch) command )

        Route.EditComment id ->
            let
                ( state, command ) =
                    Editor.loadComment (String.fromInt id) reset.editorPage
            in
            ( { reset | editorPage = state }, Cmd.map (EditorResponse epoch) command )

        Route.Search ->
            let
                ( state, command ) =
                    Search.load model.url
            in
            ( { reset | searchPage = state }, Cmd.map (SearchResponse epoch) command )

        Route.Notifications ->
            case model.auth of
                Authenticated _ ->
                    ( { reset | notificationsPage = { notifications = Loading, unreadCount = Nothing } }
                    , Cmd.map (NotificationsResponse epoch) (Notifications.load model.url)
                    )

                _ ->
                    ( reset, Cmd.none )

        Route.Profile username ->
            let
                viewer =
                    case model.auth of
                        Authenticated account ->
                            Just account

                        _ ->
                            Nothing

                ( state, command ) =
                    Profile.loadPublic model.url username (Route.query "view" model.url) viewer reset.profile
            in
            ( { reset | profile = state }, Cmd.map (ProfileResponse epoch) command )

        Route.Settings ->
            case model.auth of
                Authenticated _ ->
                    let
                        ( state, command ) =
                            AccountSettings.load
                    in
                    ( { reset | accountSettings = state }, Cmd.map (AccountSettingsResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        Route.LoginReset ->
            ( reset, Cmd.none )

        Route.Register ->
            if model.captchaEnabled then
                ( reset, Api.get "/account/auth/get_captcha" (AuthResponse epoch << Auth.CaptchaLoaded) )

            else
                ( reset, Cmd.none )

        Route.PasswordChange token ->
            ( { reset | account = AuthState.withResetToken token reset.account }, Cmd.none )

        Route.VerifyEmail token ->
            ( { reset | account = AuthState.withVerificationToken token reset.account }, Cmd.none )

        Route.PasswordSettings ->
            ( reset, Cmd.none )

        Route.AccountContent source ->
            case model.auth of
                Authenticated _ ->
                    let
                        ( state, command ) =
                            AccountContent.load source model.url reset.accountContent
                    in
                    ( { reset | accountContent = state }, Cmd.map (AccountContentResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        Route.AccountBlocks ->
            case model.auth of
                Authenticated _ ->
                    let
                        ( state, command ) =
                            AccountBlocks.load reset.accountBlocks
                    in
                    ( { reset | accountBlocks = state }, Cmd.map (AccountBlocksResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        Route.Admin ->
            adminRoute model reset Route.Admin

        Route.AdminSettings ->
            adminRoute model reset Route.AdminSettings

        Route.Reports ->
            adminRoute model reset Route.Reports

        Route.Modlog _ ->
            adminRoute model reset (Route.Modlog Nothing)

        Route.AdminBans ->
            adminRoute model reset Route.AdminBans

        Route.CommunitySettings name ->
            case model.auth of
                Authenticated _ ->
                    let
                        initial =
                            let
                                empty =
                                    ManageState.emptyManage
                            in
                            { empty
                                | community = Loading
                                , members = Ready { items = [], nextPage = Nothing, prevPage = Nothing }
                                , managers = Ready { items = [], nextPage = Nothing, prevPage = Nothing }
                                , followRequests = Loading
                                , reports = Loading
                                , modlog = Loading
                            }

                        ( state, command ) =
                            Manage.load name initial reset.management
                    in
                    ( { reset | management = state }, Cmd.map (ManageResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        _ ->
            ( reset, Cmd.none )


adminRoute : Model -> Model -> Route.Route -> ( Model, Cmd Msg )
adminRoute original reset route =
    case original.auth of
        Authenticated identity ->
            if Domain.isAdmin identity then
                let
                    ( state, command ) =
                        case route of
                            Route.AdminSettings ->
                                SiteAdmin.loadSettings reset.siteAdmin

                            Route.Reports ->
                                SiteAdmin.loadReports original.url reset.siteAdmin

                            Route.Modlog _ ->
                                SiteAdmin.loadModlog original.route original.url reset.siteAdmin

                            Route.AdminBans ->
                                SiteAdmin.loadBans reset.siteAdmin

                            _ ->
                                ( reset.siteAdmin, Cmd.none )
                in
                ( { reset | siteAdmin = state }, Cmd.map (SiteAdminResponse original.routeEpoch) command )

            else
                ( reset, Cmd.none )

        _ ->
            ( reset, Cmd.none )


loadCommunity : Model -> ( Model, Cmd Msg )
loadCommunity model =
    let
        ( state, command ) =
            Community.load model.route model.url model.communityPage
    in
    ( { model | communityPage = state }, Cmd.map (CommunityResponse model.routeEpoch) command )


unreadCommand : Model -> Cmd Msg
unreadCommand model =
    case model.auth of
        Authenticated _ ->
            Cmd.map (NotificationsResponse model.routeEpoch) Notifications.unread

        _ ->
            Cmd.none


loadSession : Model -> Cmd Msg
loadSession model =
    Cmd.batch
        [ Api.get "/account"
            (SessionLoaded model.authGeneration << Api.decodeResponse Domain.myUserInfo)
        , Api.get "/site" (SiteLoaded << Api.decodeResponse Domain.getSiteResponse)
        ]
