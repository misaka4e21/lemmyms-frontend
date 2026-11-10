module Lemmy.Api exposing (Response, decodeResponse, decodeUnit, get, login, logout, send, upload)

import File exposing (File)
import Http
import Json.Decode as Decode
import Lemmy.Problem exposing (Problem)


base : String
base =
    "/api/v4"


type alias Response =
    { status : Int, body : String }


decodeResponse : Decode.Decoder a -> Response -> Result Problem a
decodeResponse decoder response =
    if response.status >= 200 && response.status < 300 then
        Decode.decodeString decoder response.body
            |> Result.mapError (\error -> Lemmy.Problem.decode response.status (Decode.errorToString error))

    else
        Err (Lemmy.Problem.decode response.status response.body)


decodeUnit : Response -> Result Problem ()
decodeUnit response =
    if response.status >= 200 && response.status < 300 then
        Ok ()

    else
        Err (Lemmy.Problem.decode response.status response.body)


expect : (Response -> msg) -> Http.Expect msg
expect toMsg =
    Http.expectStringResponse (\result -> toMsg (Result.withDefault { status = 0, body = "" } result))
        (\response ->
            case response of
                Http.GoodStatus_ metadata body ->
                    Ok { status = metadata.statusCode, body = body }

                Http.BadStatus_ metadata body ->
                    Ok { status = metadata.statusCode, body = body }

                _ ->
                    Ok { status = 0, body = "" }
        )


get : String -> (Response -> msg) -> Cmd msg
get path toMsg =
    Http.get { url = base ++ path, expect = expect toMsg }


send : String -> String -> String -> (Response -> msg) -> Cmd msg
send method path body toMsg =
    Http.request
        { method = method
        , headers = []
        , url = base ++ path
        , body =
            if body == "" then
                Http.emptyBody

            else
                Http.stringBody "application/json" body
        , expect = expect toMsg
        , timeout = Just 30000
        , tracker = Nothing
        }


login : String -> (Response -> msg) -> Cmd msg
login body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = "/api/v3/user/login"
        , body = Http.stringBody "application/json" body
        , expect = expect toMsg
        , timeout = Just 30000
        , tracker = Nothing
        }


logout : (Response -> msg) -> Cmd msg
logout toMsg =
    send "POST" "/account/auth/logout" "" toMsg


upload : File -> (Response -> msg) -> Cmd msg
upload file toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = base ++ "/image"
        , body = Http.multipartBody [ Http.filePart "image" file ]
        , expect = expect toMsg
        , timeout = Just 120000
        , tracker = Nothing
        }
