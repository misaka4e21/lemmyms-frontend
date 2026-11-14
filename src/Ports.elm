port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Locale exposing (Locale(..))
import Ui.Formatting exposing (Formatting)


port outgoing : Encode.Value -> Cmd msg


port incoming : (Decode.Value -> msg) -> Sub msg


consumeOAuth : Cmd msg
consumeOAuth =
    outgoing (Encode.object [ ( "action", Encode.string "oauth-callback" ) ])


type IncomingData
    = IncomingFormatting Formatting
    | IncomingLayout Bool
    | IncomingOAuthCallback (Maybe OAuthCallback)
    | IncomingOAuthStartFailed
    | IncomingIgnored


type alias OAuthCallback =
    { providerId : Int
    , code : String
    , redirectUri : String
    , verifier : Maybe String
    , username : String
    , answer : String
    }


incomingDecoder : Decode.Decoder IncomingData
incomingDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\kind ->
                case kind of
                    "formatted" ->
                        Decode.map IncomingFormatting formattingDecoder

                    "layout" ->
                        Decode.map IncomingLayout (Decode.field "wide" Decode.bool)

                    "oauth-callback" ->
                        Decode.map IncomingOAuthCallback (Decode.field "result" (Decode.nullable oauthCallbackDecoder))

                    "oauth-start-failed" ->
                        Decode.succeed IncomingOAuthStartFailed

                    _ ->
                        Decode.succeed IncomingIgnored
            )


oauthCallbackDecoder : Decode.Decoder OAuthCallback
oauthCallbackDecoder =
    Decode.map6 OAuthCallback
        (Decode.field "providerId" Decode.int)
        (Decode.field "code" Decode.string)
        (Decode.field "redirectUri" Decode.string)
        (Decode.field "verifier" (Decode.nullable Decode.string))
        (Decode.field "username" Decode.string)
        (Decode.field "answer" Decode.string)


formattingDecoder : Decode.Decoder Formatting
formattingDecoder =
    Decode.map3 Formatting
        (Decode.field "locale" Decode.string)
        (Decode.field "numbers" (Decode.list pairedIntString))
        (Decode.field "plurals" (Decode.list pairedIntString))


pairedIntString : Decode.Decoder ( Int, String )
pairedIntString =
    Decode.oneOf
        [ Decode.map2 Tuple.pair (Decode.field "source" Decode.int) (Decode.field "text" Decode.string)
        , Decode.map2 Tuple.pair (Decode.field "source" Decode.int) (Decode.field "category" Decode.string)
        ]


setLocale : Locale -> Cmd msg
setLocale locale =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "locale" )
            , ( "locale", Encode.string (Locale.code locale) )
            ]
        )


requestFormatting : Locale -> Cmd msg
requestFormatting locale =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "format" )
            , ( "locale", Encode.string (Locale.code locale) )
            , ( "numbers", Encode.list Encode.int [ 1, 3, 1234567 ] )
            , ( "plurals", Encode.list Encode.int [ 1, 3 ] )
            ]
        )


focus : String -> Cmd msg
focus identifier =
    outgoing (Encode.object [ ( "action", Encode.string "focus" ), ( "id", Encode.string identifier ) ])


replaceRange : { id : String, start : Int, end : Int, text : String, caret : Int } -> Cmd msg
replaceRange replacement =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "replace-range" )
            , ( "id", Encode.string replacement.id )
            , ( "start", Encode.int replacement.start )
            , ( "end", Encode.int replacement.end )
            , ( "text", Encode.string replacement.text )
            , ( "caret", Encode.int replacement.caret )
            ]
        )


openDialog : String -> Cmd msg
openDialog identifier =
    outgoing (Encode.object [ ( "action", Encode.string "dialog-open" ), ( "id", Encode.string identifier ) ])


closeDialog : String -> Cmd msg
closeDialog identifier =
    outgoing (Encode.object [ ( "action", Encode.string "dialog-close" ), ( "id", Encode.string identifier ) ])


setTheme : String -> Cmd msg
setTheme theme =
    outgoing (Encode.object [ ( "action", Encode.string "theme" ), ( "theme", Encode.string theme ) ])


download : String -> String -> Cmd msg
download filename content =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "download" )
            , ( "filename", Encode.string filename )
            , ( "content", Encode.string content )
            ]
        )
