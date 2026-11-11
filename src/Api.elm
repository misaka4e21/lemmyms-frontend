module Api exposing (Problem, Response, decodeResponse, decodeUnit, get, login, send, upload, uploadTo)

import File exposing (File)
import Http
import Json.Decode as Decode
import Lemmy.Problem as LemmyProblem


base : String
base =
    "/api/v4"


type alias Response =
    { status : Int, body : String }


type alias Problem =
    { status : Int, detail : String }


decodeResponse : Decode.Decoder a -> Response -> Result Problem a
decodeResponse decoder response =
    if response.status >= 200 && response.status < 300 then
        Decode.decodeString decoder response.body
            |> Result.mapError (\error -> { status = response.status, detail = Decode.errorToString error })

    else
        Err (problem response)


decodeUnit : Response -> Result Problem ()
decodeUnit response =
    if response.status >= 200 && response.status < 300 then
        Ok ()

    else
        Err (problem response)


problem : Response -> Problem
problem response =
    let
        value =
            LemmyProblem.decode response.status response.body
    in
    { status = response.status, detail = value.code }


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
get url toMsg =
    Http.get { url = base ++ url, expect = expect toMsg }


send : String -> String -> String -> String -> (Response -> msg) -> Cmd msg
send csrf method url body toMsg =
    let
        _ =
            csrf
    in
    Http.request
        { method = method
        , headers = []
        , url = base ++ url
        , body =
            if body == "" then
                Http.emptyBody

            else
                Http.stringBody "application/json" body
        , expect = expect toMsg
        , timeout = Just 30000
        , tracker = Nothing
        }


upload : String -> String -> File -> (Response -> msg) -> Cmd msg
upload csrf purpose file toMsg =
    let
        _ =
            ( csrf, purpose )
    in
    Http.request
        { method = "POST"
        , headers = []
        , url = base ++ "/image"
        , body = Http.multipartBody [ Http.filePart "image" file ]
        , expect = expect toMsg
        , timeout = Just 120000
        , tracker = Nothing
        }


uploadTo : String -> File -> (Response -> msg) -> Cmd msg
uploadTo path file toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = base ++ path
        , body = Http.multipartBody [ Http.filePart "image" file ]
        , expect = expect toMsg
        , timeout = Just 120000
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
