module Lemmy.Problem exposing (Problem, codeForStatus, decode, isConflict, isForbidden, isNotFound, isRateLimited, isUnauthenticated, isValidation, statusText)

import Json.Decode as D


type alias Problem =
    { status : Int
    , code : String
    , message : Maybe String
    }


decode : Int -> String -> Problem
decode status body =
    case D.decodeString errorBody body of
        Ok value ->
            { status = status, code = value.code, message = value.message }

        Err _ ->
            { status = status, code = codeForStatus status, message = Nothing }


errorBody : D.Decoder { code : String, message : Maybe String }
errorBody =
    D.map2
        (\code message -> { code = code, message = message })
        (D.field "error" D.string)
        (D.oneOf [ D.field "message" D.string |> D.map Just, D.succeed Nothing ])


codeForStatus : Int -> String
codeForStatus status =
    case status of
        400 ->
            "bad_request"

        401 ->
            "not_logged_in"

        403 ->
            "not_an_admin"

        404 ->
            "not_found"

        409 ->
            "conflict"

        429 ->
            "too_many_requests"

        503 ->
            "unavailable"

        _ ->
            "unknown"


isUnauthenticated : Problem -> Bool
isUnauthenticated problem =
    problem.status == 401 || problem.code == "not_logged_in"


isForbidden : Problem -> Bool
isForbidden problem =
    problem.status == 403 || problem.code == "not_an_admin" || problem.code == "not_a_moderator"


isNotFound : Problem -> Bool
isNotFound problem =
    problem.status == 404 || problem.code == "not_found"


isConflict : Problem -> Bool
isConflict problem =
    problem.status == 409 || problem.code == "conflict"


isRateLimited : Problem -> Bool
isRateLimited problem =
    problem.status == 429 || problem.code == "too_many_requests"


isValidation : Problem -> Bool
isValidation problem =
    problem.status == 400 || problem.code == "bad_request"


statusText : Problem -> String
statusText problem =
    problem.code
