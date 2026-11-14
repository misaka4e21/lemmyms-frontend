module Feature.FederationPolicy exposing (Field(..), Item, Model, body, change, decoder, initial, load, page, valid)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, button, div, form, input, label, li, option, p, select, text, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as D
import Json.Encode as E
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias Item =
    { domain : String, allowed : Bool, blocked : Bool }


type alias Model =
    { items : Remote (Domain.Page Item)
    , domain : String
    , reason : String
    , action : String
    , expires : String
    , busy : Bool
    , problem : Maybe Api.Problem
    }


type Field
    = DomainField
    | ReasonField
    | ActionField
    | ExpiresField


initial : Model
initial =
    { items = NotAsked, domain = "", reason = "", action = "allow", expires = "", busy = False, problem = Nothing }


decoder : D.Decoder (Domain.Page Item)
decoder =
    Domain.page
        (D.map3 Item
            (D.at [ "instance", "domain" ] D.string)
            (present "allowed")
            (present "blocked")
        )


present : String -> D.Decoder Bool
present name =
    D.oneOf [ D.field name (D.nullable D.value) |> D.map (Maybe.map (always True) >> Maybe.withDefault False), D.succeed False ]


load : AuthState -> Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth url loaded =
    case auth of
        Authenticated user ->
            if Domain.isAdmin user then
                ( { initial | items = Loading }
                , Api.get
                    ("/federated_instances"
                        ++ Builder.toQuery
                            ([ Builder.string "kind" "all", Builder.int "limit" 20 ]
                                ++ (case Route.cursor url of
                                        Just cursor ->
                                            [ Builder.string "page_cursor" cursor ]

                                        Nothing ->
                                            []
                                   )
                            )
                    )
                    loaded
                )

            else
                ( initial, Cmd.none )

        _ ->
            ( initial, Cmd.none )


change : Field -> String -> Model -> Model
change field value current =
    case field of
        DomainField ->
            { current | domain = value }

        ReasonField ->
            { current | reason = value }

        ActionField ->
            { current | action = value }

        ExpiresField ->
            { current | expires = value }


valid : Model -> Bool
valid current =
    not (String.isEmpty (String.trim current.domain))
        && not (String.isEmpty (String.trim current.reason))
        && List.member current.action [ "allow", "unallow", "block", "unblock" ]
        && expiryValid current


expiryValid : Model -> Bool
expiryValid current =
    current.action /= "block" || String.isEmpty current.expires || (String.toInt current.expires |> Maybe.map ((<) 0) |> Maybe.withDefault False)


body : Model -> ( String, String )
body current =
    let
        block =
            List.member current.action [ "block", "unblock" ]

        enabled =
            List.member current.action [ "allow", "block" ]

        expiry =
            if current.action == "block" then
                String.toInt current.expires |> Maybe.map (\value -> [ ( "expires_at", E.int value ) ]) |> Maybe.withDefault []

            else
                []
    in
    ( if block then
        "/admin/instance/block"

      else
        "/admin/instance/allow"
    , E.object
        ([ ( "instance", E.string (String.trim current.domain) )
         , ( "reason", E.string (String.trim current.reason) )
         , ( if block then
                "block"

             else
                "allow"
           , E.bool enabled
           )
         ]
            ++ expiry
        )
        |> E.encode 0
    )


page : { retry : msg, changed : Field -> String -> msg, submit : msg } -> Active -> AuthState -> Url -> Model -> Html msg
page config active auth url model =
    pageHeading (T.federationPolicy active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    div [ A.class "stack" ]
                        [ form [ A.class "card form-stack", Events.onSubmit config.submit ]
                            [ p [] [ text (T.federationPolicyHelp active.texts) ]
                            , label [ A.for "federation-domain" ] [ text (T.instanceDomain active.texts) ]
                            , input [ A.id "federation-domain", A.required True, A.value model.domain, Events.onInput (config.changed DomainField) ] []
                            , label [ A.for "federation-reason" ] [ text (T.reason active.texts) ]
                            , input [ A.id "federation-reason", A.required True, A.value model.reason, Events.onInput (config.changed ReasonField) ] []
                            , label [ A.for "federation-action" ] [ text (T.federationAction active.texts) ]
                            , select [ A.id "federation-action", Events.onInput (config.changed ActionField) ]
                                (List.map (actionOption active model.action) [ "allow", "unallow", "block", "unblock" ])
                            , if model.action == "block" then
                                div []
                                    [ label [ A.for "federation-expires" ] [ text (T.federationExpires active.texts) ]
                                    , input
                                        ([ A.id "federation-expires", A.type_ "number", A.min "1", A.value model.expires, Events.onInput (config.changed ExpiresField) ]
                                            ++ (if expiryValid model then
                                                    []

                                                else
                                                    [ A.attribute "aria-invalid" "true", A.attribute "aria-describedby" "federation-expires-error" ]
                                               )
                                        )
                                        []
                                    , if expiryValid model then
                                        text ""

                                      else
                                        p [ A.id "federation-expires-error", A.class "field-error", A.attribute "role" "alert" ] [ text (T.invalidInput active.texts) ]
                                    ]

                              else
                                text ""
                            , viewFormProblem active.texts model.problem
                            , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.busy || not (valid model)) ] [ text (T.saveChanges active.texts) ]
                            ]
                        , viewRemote config.retry
                            active.texts
                            model.items
                            (\results ->
                                div [ A.class "stack" ]
                                    [ if List.isEmpty results.items then
                                        p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                                      else
                                        ul [] (List.map (itemView active) results.items)
                                    , viewPagination active.texts url results.prevPage results.nextPage
                                    ]
                            )
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


actionOption : Active -> String -> String -> Html msg
actionOption active selected value =
    option [ A.value value, A.selected (selected == value) ]
        [ text
            (case value of
                "unallow" ->
                    T.federationUnallow active.texts

                "block" ->
                    T.federationBlock active.texts

                "unblock" ->
                    T.federationUnblock active.texts

                _ ->
                    T.federationAllow active.texts
            )
        ]


itemView : Active -> Item -> Html msg
itemView active item =
    li []
        [ text
            (item.domain
                ++ " · "
                ++ (if item.allowed then
                        T.instanceKindAllowed active.texts

                    else if item.blocked then
                        T.instanceKindBlocked active.texts

                    else
                        T.federationLinked active.texts
                   )
            )
        ]
