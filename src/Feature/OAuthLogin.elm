module Feature.OAuthLogin exposing (CallbackState(..), Model, body, callbackPage, initial, providerPanel, start)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, a, button, div, input, label, p, section, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Encode as E
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Ports exposing (OAuthCallback, outgoing)
import Ui.Feedback exposing (problemText)
import Ui.Layout exposing (pageHeading)


type CallbackState
    = NotStarted
    | Checking
    | Invalid
    | Ready OAuthCallback
    | Submitting
    | ApplicationSent
    | VerificationSent
    | SessionFailed
    | Failed Api.Problem


type alias Model =
    { providers : List Domain.PublicOAuthProvider
    , username : String
    , answer : String
    , totp : String
    , starting : Bool
    , startFailed : Bool
    , callback : CallbackState
    }


initial : Model
initial =
    { providers = [], username = "", answer = "", totp = "", starting = False, startFailed = False, callback = NotStarted }


start : Domain.PublicOAuthProvider -> Model -> Cmd msg
start provider model =
    outgoing
        (E.object
            [ ( "action", E.string "oauth-start" )
            , ( "provider"
              , E.object
                    [ ( "id", E.int provider.id )
                    , ( "authorizationEndpoint", E.string provider.authorizationEndpoint )
                    , ( "clientId", E.string provider.clientId )
                    , ( "scopes", E.string provider.scopes )
                    , ( "usePkce", E.bool provider.usePkce )
                    ]
              )
            , ( "details", E.object [ ( "username", E.string model.username ), ( "answer", E.string model.answer ) ] )
            ]
        )


body : OAuthCallback -> String -> String
body callback totp =
    E.object
        ([ ( "code", E.string callback.code )
         , ( "oauth_provider_id", E.int callback.providerId )
         , ( "redirect_uri", E.string callback.redirectUri )
         , ( "stay_logged_in", E.bool True )
         ]
            ++ optional "pkce_code_verifier" (Maybe.withDefault "" callback.verifier)
            ++ optional "username" callback.username
            ++ optional "answer" callback.answer
            ++ optional "totp_2fa_token" totp
        )
        |> E.encode 0


optional : String -> String -> List ( String, E.Value )
optional key value =
    if String.isEmpty (String.trim value) then
        []

    else
        [ ( key, E.string value ) ]


providerPanel : { username : String -> msg, answer : String -> msg, start : Domain.PublicOAuthProvider -> msg } -> Active -> AuthState -> Model -> Html msg
providerPanel config active auth model =
    case auth of
        Authenticated _ ->
            text ""

        _ ->
            if List.isEmpty model.providers then
                text ""

            else
                section [ A.class "card form-stack" ]
                    [ p [] [ text (T.oauthLogin active.texts) ]
                    , label [ A.for "oauth-username" ] [ text (T.oauthRegisterUsername active.texts) ]
                    , input [ A.id "oauth-username", A.value model.username, Events.onInput config.username ] []
                    , label [ A.for "oauth-answer" ] [ text (T.oauthRegisterAnswer active.texts) ]
                    , textarea [ A.id "oauth-answer", A.value model.answer, Events.onInput config.answer ] []
                    , if model.startFailed then
                        p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.oauthStartFailed active.texts) ]

                      else
                        text ""
                    , div [ A.class "actions" ]
                        (List.map
                            (\provider -> button [ A.type_ "button", A.class "outlined-button", A.disabled model.starting, Events.onClick (config.start provider) ] [ text provider.displayName ])
                            model.providers
                        )
                    ]


callbackPage : { totp : String -> msg, submit : msg } -> Active -> Model -> Html msg
callbackPage config active model =
    pageHeading (T.oauthCallback active.texts)
        (case model.callback of
            NotStarted ->
                failure active (T.oauthInvalid active.texts)

            Checking ->
                p [ A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

            Invalid ->
                failure active (T.oauthInvalid active.texts)

            Ready _ ->
                div [ A.class "card form-stack" ]
                    [ label [ A.for "oauth-totp" ] [ text (T.oauthTotp active.texts) ]
                    , input [ A.id "oauth-totp", A.type_ "text", A.value model.totp, Events.onInput config.totp ] []
                    , button [ A.type_ "button", A.class "filled-button", Events.onClick config.submit ] [ text (T.oauthContinue active.texts) ]
                    ]

            Submitting ->
                p [ A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

            ApplicationSent ->
                p [ A.attribute "role" "status" ] [ text (T.oauthApplicationSent active.texts) ]

            VerificationSent ->
                p [ A.attribute "role" "status" ] [ text (T.oauthVerificationSent active.texts) ]

            SessionFailed ->
                failure active (T.oauthSessionFailed active.texts)

            Failed problem ->
                failure active (oauthProblem active problem)
        )


oauthProblem : Active -> Api.Problem -> String
oauthProblem active problem =
    case problem.detail of
        "registration_username_required" ->
            T.oauthUsernameRequired active.texts

        "registration_application_answer_required" ->
            T.oauthAnswerRequired active.texts

        "missing_totp_token" ->
            T.oauthTotpInvalid active.texts

        "incorrect_totp_token" ->
            T.oauthTotpInvalid active.texts

        _ ->
            problemText active.texts problem


failure : Active -> String -> Html msg
failure active message =
    div [ A.class "card form-stack" ]
        [ p [ A.attribute "role" "alert" ] [ text message ]
        , a [ A.href (Route.path Route.Login), A.class "outlined-button" ] [ text (T.loginTitle active.texts) ]
        ]
