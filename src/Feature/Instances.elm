module Feature.Instances exposing (Model, decoder, initial, load, page, title)

import Api
import App.Context exposing (Active)
import Generated.I18n as T
import Html exposing (Html, button, div, form, input, label, li, option, p, select, text, ul)
import Html.Attributes as A
import Json.Decode as D
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias Model =
    Remote (Domain.Page String)


initial : Model
initial =
    NotAsked


decoder : D.Decoder (Domain.Page String)
decoder =
    Domain.page (D.at [ "instance", "domain" ] D.string)


title : T.I18n -> String
title =
    T.federatedInstances


load : Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load url response =
    let
        kind =
            selectedKind url

        params =
            [ Builder.string "kind" kind, Builder.int "limit" 20 ]
                ++ optional "domain_filter" (Route.query "domain_filter" url)
                ++ optional "page_cursor" (Route.query "page_cursor" url)
    in
    ( Loading, Api.get ("/federated_instances" ++ Builder.toQuery params) response )


optional : String -> String -> List Builder.QueryParameter
optional name value =
    if String.isEmpty value then
        []

    else
        [ Builder.string name value ]


selectedKind : Url -> String
selectedKind url =
    let
        kind =
            Route.query "kind" url
    in
    if List.member kind [ "all", "linked", "allowed", "blocked" ] then
        kind

    else
        "all"


page : msg -> Active -> Url -> Model -> Html msg
page retry active url model =
    pageHeading (title active.texts)
        (div [ A.class "stack" ]
            [ form [ A.action "/instances", A.method "get", A.class "card form-stack" ]
                [ label [ A.for "instance-domain" ] [ text (T.instanceDomain active.texts) ]
                , input [ A.id "instance-domain", A.name "domain_filter", A.value (Route.query "domain_filter" url) ] []
                , label [ A.for "instance-kind" ] [ text (T.filter active.texts) ]
                , select [ A.id "instance-kind", A.name "kind" ]
                    (List.map (kindOption active.texts (selectedKind url)) [ "all", "linked", "allowed", "blocked" ])
                , button [ A.type_ "submit", A.class "filled-button" ] [ text (T.filter active.texts) ]
                ]
            , viewRemote retry
                active.texts
                model
                (\result ->
                    div [ A.class "stack" ]
                        [ if List.isEmpty result.items then
                            p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                          else
                            ul [] (List.map (\domain -> li [] [ text domain ]) result.items)
                        , viewPagination active.texts url result.prevPage result.nextPage
                        ]
                )
            ]
        )


kindOption : T.I18n -> String -> String -> Html msg
kindOption texts selected value =
    option [ A.value value, A.selected (selected == value) ] [ text (labelFor texts value) ]


labelFor : T.I18n -> String -> String
labelFor texts key =
    case key of
        "linked" ->
            T.instanceKindLinked texts

        "allowed" ->
            T.instanceKindAllowed texts

        "blocked" ->
            T.instanceKindBlocked texts

        _ ->
            T.instanceKindAll texts
