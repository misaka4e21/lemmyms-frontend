module App.View.Account exposing (pageLogin, pagePasswordReset, pagePasswordResetConfirm, pagePasswordSettings, pagePublicProfile, pageRegister, pageSettings, pageVerify)

import App.Context exposing (Active)
import App.State exposing (Model, Msg(..))
import Browser
import Feature.AccountSettings as AccountSettings
import Feature.Auth.Update as Auth
import Feature.Auth.View
import Feature.OAuthLogin as OAuthLogin
import Feature.Profile as Profile
import Html exposing (Html)
import Lemmy.Domain as Domain
import Url


pageLogin : Model -> Active -> Html Msg
pageLogin model active =
    Html.div []
        [ Feature.Auth.View.pageLogin (authViewConfig model) model.auth model.account active
        , OAuthLogin.providerPanel
            { username = OAuthUsernameChanged, answer = OAuthAnswerChanged, start = OAuthStart }
            active
            model.auth
            model.oauthLogin
        ]


pageRegister : Model -> Active -> Html Msg
pageRegister model active =
    Feature.Auth.View.pageRegister (authViewConfig model)
        model.auth
        model.account
        active
        (Maybe.map
            (\site ->
                { mode = site.localSite.registrationMode
                , applicationQuestion = site.localSite.applicationQuestion
                , captchaEnabled = model.captchaEnabled
                }
            )
            model.site
        )


pageVerify : Model -> Active -> Html Msg
pageVerify model active =
    Feature.Auth.View.pageVerify (authViewConfig model) model.auth model.account active


pagePasswordReset : Model -> Active -> Html Msg
pagePasswordReset model active =
    Feature.Auth.View.pagePasswordReset (authViewConfig model) model.auth model.account active


pagePasswordResetConfirm : Model -> Active -> Html Msg
pagePasswordResetConfirm model active =
    Feature.Auth.View.pagePasswordResetConfirm (authViewConfig model) model.auth model.account active


pagePasswordSettings : Model -> Active -> Html Msg
pagePasswordSettings model active =
    Feature.Auth.View.pagePasswordSettings (authViewConfig model) model.auth model.account active


authViewConfig : Model -> Feature.Auth.View.Config Msg
authViewConfig model =
    { retry = RetryPage
    , loginIdentifierChanged = AuthMessage << Auth.LoginIdentifierChanged
    , loginPasswordChanged = AuthMessage << Auth.LoginPasswordChanged
    , loginSubmitted = AuthMessage Auth.LoginSubmitted
    , logout = AuthMessage Auth.Logout
    , registerUsernameChanged = AuthMessage << Auth.RegisterUsernameChanged
    , registerEmailChanged = AuthMessage << Auth.RegisterEmailChanged
    , registerPasswordChanged = AuthMessage << Auth.RegisterPasswordChanged
    , registerPasswordVerifyChanged = AuthMessage << Auth.RegisterPasswordVerifyChanged
    , registerApplicationAnswerChanged = AuthMessage << Auth.RegisterApplicationAnswerChanged
    , registerInviteTokenChanged = AuthMessage << Auth.RegisterInviteTokenChanged
    , captchaAnswerChanged = AuthMessage << Auth.CaptchaAnswerChanged
    , loadCaptcha = AuthMessage Auth.LoadCaptcha
    , registerSubmitted = AuthMessage Auth.RegisterSubmitted
    , resendSubmitted = AuthMessage Auth.ResendSubmitted
    , verifyPasswordChanged = AuthMessage << Auth.VerifyPasswordChanged
    , verifySubmitted = AuthMessage Auth.VerifySubmitted
    , resetEmailChanged = AuthMessage << Auth.ResetEmailChanged
    , resetRequested = AuthMessage Auth.ResetRequested
    , resetNewPasswordChanged = AuthMessage << Auth.ResetNewPasswordChanged
    , resetSubmitted = AuthMessage Auth.ResetSubmitted
    , changeCurrentPasswordChanged = AuthMessage << Auth.ChangeCurrentPasswordChanged
    , changeNewPasswordChanged = AuthMessage << Auth.ChangeNewPasswordChanged
    , changePasswordSubmitted = AuthMessage Auth.ChangePasswordSubmitted
    }


pagePublicProfile : (Domain.PostView -> Html Msg) -> Model -> Active -> String -> Html Msg
pagePublicProfile postCard model active username =
    Profile.pagePublicProfile
        (profileViewConfig postCard model)
        { publicProfile = model.profile.publicProfile
        , ownProfile = model.profile.ownProfile
        , profileForm = model.profile.profileForm
        , auth = model.auth
        , content = model.profile.content
        , contentView = model.profile.contentView
        , url = model.url
        }
        active
        username


pageSettings : Model -> Active -> Html Msg
pageSettings model active =
    Html.map AccountSettingsMessage (AccountSettings.view active model.auth model.accountSettings)


profileViewConfig : (Domain.PostView -> Html Msg) -> Model -> Profile.Config Msg
profileViewConfig postCard model =
    { retry = RetryPage
    , profileDisplayNameChanged = ProfileMessage << Profile.ProfileDisplayNameChanged
    , profileAuthoring = ProfileMessage << Profile.ProfileAuthoring
    , profileClearAvatar = ProfileMessage Profile.ProfileClearAvatar
    , profileSave = ProfileMessage Profile.ProfileSave
    , avatarFileSelected = ProfileMessage << Profile.AvatarFileSelected
    , postCard = postCard
    , tabNavigate = \path -> Navigate (Browser.Internal (absoluteUrl model.url path))
    }


absoluteUrl : Url.Url -> String -> Url.Url
absoluteUrl current path =
    case Url.fromString ("https://local" ++ path) of
        Just parsed ->
            { parsed | protocol = current.protocol, host = current.host, port_ = current.port_ }

        Nothing ->
            current
