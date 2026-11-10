module LemmyAuthTest exposing (suite)

import Expect
import Json.Decode as Decode
import Lemmy.Auth as Auth
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Lemmy login bridge"
        [ test "encodes credentials for the v3 cookie bridge" <|
            \_ ->
                let
                    body =
                        Auth.loginBody
                            { usernameOrEmail = "alice"
                            , password = "secret"
                            , totp = ""
                            , stayLoggedIn = True
                            }

                    decoder =
                        Decode.map2 (\user pass -> ( user, pass ))
                            (Decode.field "username_or_email" Decode.string)
                            (Decode.field "password" Decode.string)
                in
                Expect.equal (Ok ( "alice", "secret" ))
                    (Decode.decodeString decoder body)
        , test "omits an empty TOTP token" <|
            \_ ->
                let
                    body =
                        Auth.loginBody
                            { usernameOrEmail = "alice"
                            , password = "secret"
                            , totp = ""
                            , stayLoggedIn = False
                            }

                    hasTotp =
                        Decode.decodeString (Decode.field "totp_2fa_token" Decode.string) body
                            |> Result.toMaybe
                in
                Expect.equal Nothing hasTotp
        , test "includes a supplied TOTP token" <|
            \_ ->
                let
                    body =
                        Auth.loginBody
                            { usernameOrEmail = "alice"
                            , password = "secret"
                            , totp = "123456"
                            , stayLoggedIn = False
                            }
                in
                Expect.equal (Ok "123456")
                    (Decode.decodeString (Decode.field "totp_2fa_token" Decode.string) body)
        ]
