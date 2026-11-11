module App.Access exposing (authProblem, clearPrivate)

import Api
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import App.State exposing (Model)
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.AccountSettings as AccountSettings
import Feature.CommunityManage.State as ManageState
import Feature.MultiCommunity as MultiCommunity
import Feature.Notifications as Notifications
import Feature.Profile as Profile
import Feature.Report as Report
import Feature.SiteAdmin.State as SiteAdminState
import Remote exposing (Remote(..))
import Set exposing (Set)


authProblem : Model -> Api.Problem -> Model
authProblem model problem =
    if problem.status == 401 then
        clearPrivate
            { model | auth = Anonymous, authGeneration = model.authGeneration + 1, flash = FlashProblem problem }

    else
        model


clearPrivate : Model -> Model
clearPrivate model =
    { model
        | profile = Profile.clearPrivate model.profile
        , drawerProfile = NotAsked
        , notificationsPage = Notifications.initial
        , multiCommunity = MultiCommunity.initial
        , management = ManageState.initial
        , accountContent = AccountContent.initial
        , accountSettings = AccountSettings.initial
        , accountBlocks = AccountBlocks.initial
        , report = Report.initial
        , siteAdmin = SiteAdminState.initial
        , commentTarget = NotAsked
        , donationPrompt = False
        , posts = (\postsState -> { postsState | busy = Set.empty }) model.posts
    }
