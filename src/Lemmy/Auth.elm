module Lemmy.Auth exposing (LoginForm, loadSession, login, loginBody, logout)

import Json.Encode as Encode
import Lemmy.Api as Api


type alias LoginForm =
    { usernameOrEmail : String
    , password : String
    , totp : String
    , stayLoggedIn : Bool
    }


loginBody : LoginForm -> String
loginBody form =
    Encode.encode 0
        (Encode.object
            ([ ( "username_or_email", Encode.string form.usernameOrEmail )
             , ( "password", Encode.string form.password )
             , ( "stay_logged_in", Encode.bool form.stayLoggedIn )
             ]
                ++ (if String.isEmpty form.totp then
                        []

                    else
                        [ ( "totp_2fa_token", Encode.string form.totp ) ]
                   )
            )
        )


login : LoginForm -> (Api.Response -> msg) -> Cmd msg
login form toMsg =
    Api.login (loginBody form) toMsg


loadSession : (Api.Response -> msg) -> Cmd msg
loadSession toMsg =
    Api.get "/account" toMsg


logout : (Api.Response -> msg) -> Cmd msg
logout toMsg =
    Api.logout toMsg
