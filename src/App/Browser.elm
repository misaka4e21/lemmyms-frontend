module App.Browser exposing (receiveIncoming)

import App.Layout exposing (applyLayout)
import App.State exposing (Model, Msg(..))
import Feature.OAuthLogin as OAuthLogin
import Json.Decode as Decode
import Lemmy.Route as Route
import Locale exposing (Locale(..))
import Ports exposing (IncomingData(..), incomingDecoder)


receiveIncoming : Decode.Value -> Model -> ( Model, Cmd Msg )
receiveIncoming raw model =
    case Decode.decodeValue incomingDecoder raw of
        Ok (IncomingFormatting currentFormatting) ->
            case model.active of
                Just active ->
                    if currentFormatting.locale == Locale.code active.locale then
                        ( { model | formatted = Just currentFormatting }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Ok (IncomingLayout wide) ->
            let
                next =
                    applyLayout wide
                        { wideLayout = model.wideLayout
                        , drawerOpen = model.drawerOpen
                        }
            in
            ( { model | wideLayout = next.wideLayout, drawerOpen = next.drawerOpen }, Cmd.none )

        Ok (IncomingOAuthCallback result) ->
            if model.route == Route.OAuthCallback then
                let
                    previous =
                        model.oauthLogin

                    currentUrl =
                        model.url
                in
                ( { model
                    | url = { currentUrl | query = Nothing, fragment = Nothing }
                    , oauthLogin =
                        { previous
                            | callback = Maybe.map OAuthLogin.Ready result |> Maybe.withDefault OAuthLogin.Invalid
                            , username = Maybe.map .username result |> Maybe.withDefault previous.username
                            , answer = Maybe.map .answer result |> Maybe.withDefault previous.answer
                        }
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Ok IncomingOAuthStartFailed ->
            let
                previous =
                    model.oauthLogin
            in
            ( { model | oauthLogin = { previous | starting = False, startFailed = True } }, Cmd.none )

        Ok IncomingIgnored ->
            ( model, Cmd.none )

        Err _ ->
            ( model, Cmd.none )
