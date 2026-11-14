module Feature.ExternalInteraction exposing (decoder, load)

import Api
import Json.Decode as D
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Url exposing (Url)
import Url.Builder as Builder


load : Url -> (Api.Response -> msg) -> ( Remote (), Cmd msg )
load url response =
    let
        uri =
            String.trim (Route.query "uri" url)
    in
    case Url.fromString uri of
        Just _ ->
            ( Loading, Api.get ("/resolve_object" ++ Builder.toQuery [ Builder.string "q" uri ]) response )

        Nothing ->
            ( Failed { status = 400, detail = "invalid_input" }, Cmd.none )


decoder : D.Decoder Route.Route
decoder =
    D.field "type_" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "post" ->
                        D.map (\id -> Route.Post id Nothing) (D.at [ "post", "id" ] Domain.identifier)

                    "comment" ->
                        D.map Route.Comment (D.at [ "comment", "id" ] Domain.identifier)

                    "community" ->
                        D.map Route.Community (handle "community")

                    "person" ->
                        D.map Route.Profile (handle "person")

                    "multi_community" ->
                        D.map Route.MultiCommunity (handle "multi")

                    _ ->
                        D.fail "Unsupported object type"
            )


handle : String -> D.Decoder String
handle field =
    D.map3
        (\name local apId -> ( name, local, apId ))
        (D.at [ field, "name" ] D.string)
        (D.at [ field, "local" ] D.bool)
        (D.at [ field, "ap_id" ] D.string)
        |> D.andThen
            (\( name, local, apId ) ->
                if local then
                    D.succeed name

                else
                    case Url.fromString apId of
                        Just actor ->
                            D.succeed (name ++ "@" ++ actor.host)

                        Nothing ->
                            D.fail "Invalid actor URL"
            )
