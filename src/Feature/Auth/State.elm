module Feature.Auth.State exposing (Model, initial, withResetToken, withVerificationToken)

import Api
import Lemmy.Domain as Domain


type alias Model =
    { verificationToken : String
    , loginIdentifier : String
    , loginPassword : String
    , loginProblem : Maybe Api.Problem
    , loginBusy : Bool
    , registerUsername : String
    , registerEmail : String
    , registerPassword : String
    , registerPasswordVerify : String
    , registerApplicationAnswer : String
    , registerInviteToken : String
    , captcha : Maybe Domain.Captcha
    , captchaAnswer : String
    , captchaProblem : Maybe Api.Problem
    , captchaBusy : Bool
    , registerNotice : Maybe String
    , registerProblem : Maybe Api.Problem
    , registerBusy : Bool
    , verifyPassword : String
    , verifyProblem : Maybe Api.Problem
    , verifyBusy : Bool
    , verified : Bool
    , resetEmail : String
    , resetProblem : Maybe Api.Problem
    , resetAccepted : Bool
    , resetToken : String
    , resetNewPassword : String
    , resetBusy : Bool
    , resetComplete : Bool
    , changeCurrentPassword : String
    , changeNewPassword : String
    , changeProblem : Maybe Api.Problem
    , changeBusy : Bool
    }


initial : String -> Model
initial token =
    { verificationToken = token
    , loginIdentifier = ""
    , loginPassword = ""
    , loginProblem = Nothing
    , loginBusy = False
    , registerUsername = ""
    , registerEmail = ""
    , registerPassword = ""
    , registerPasswordVerify = ""
    , registerApplicationAnswer = ""
    , registerInviteToken = ""
    , captcha = Nothing
    , captchaAnswer = ""
    , captchaProblem = Nothing
    , captchaBusy = False
    , registerNotice = Nothing
    , registerProblem = Nothing
    , registerBusy = False
    , verifyPassword = ""
    , verifyProblem = Nothing
    , verifyBusy = False
    , verified = False
    , resetEmail = ""
    , resetProblem = Nothing
    , resetAccepted = False
    , resetToken = ""
    , resetNewPassword = ""
    , resetBusy = False
    , resetComplete = False
    , changeCurrentPassword = ""
    , changeNewPassword = ""
    , changeProblem = Nothing
    , changeBusy = False
    }


withResetToken : String -> Model -> Model
withResetToken token model =
    { model | resetToken = token, resetComplete = False }


withVerificationToken : String -> Model -> Model
withVerificationToken token model =
    { model | verificationToken = token, verifyProblem = Nothing, verified = False }
