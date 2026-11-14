module Feature.RegistrationApplications exposing (Application, Model, allowed, decoder, initial, load, page, title)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict exposing (Dict)
import Generated.I18n as T
import Html exposing (Html, button, div, form, input, label, p, section, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as D
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (viewFormProblem, viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias Application =
    { id : Int, answer : String, publishedAt : String, denyReason : Maybe String, creator : Domain.Person }


type alias Model =
    { requests : Remote (Domain.Page Application)
    , drafts : Dict Int String
    , submitting : Bool
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { requests = NotAsked, drafts = Dict.empty, submitting = False, problem = Nothing }


decoder : D.Decoder Application
decoder =
    D.map5 Application
        (D.at [ "registration_application", "id" ] Domain.identifier)
        (D.at [ "registration_application", "answer" ] D.string)
        (D.at [ "registration_application", "published_at" ] D.string)
        (D.oneOf [ D.at [ "registration_application", "deny_reason" ] (D.nullable D.string), D.succeed Nothing ])
        (D.field "creator" Domain.person)


allowed : AuthState -> Bool
allowed auth =
    case auth of
        Authenticated account ->
            Domain.isAdmin account

        _ ->
            False


title : T.I18n -> String
title =
    T.registrationApplications


load : AuthState -> Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth url response =
    if allowed auth then
        ( { initial | requests = Loading }
        , Api.get
            ("/admin/registration_application/list"
                ++ Builder.toQuery
                    ([ Builder.int "limit" 20
                     , Builder.string "unread_only"
                        (if Route.query "unread_only" url == "true" then
                            "true"

                         else
                            "false"
                        )
                     ]
                        ++ (case Route.cursor url of
                                Just cursor ->
                                    [ Builder.string "page_cursor" cursor ]

                                Nothing ->
                                    []
                           )
                    )
            )
            response
        )

    else
        ( initial, Cmd.none )


page : { retry : msg, changeReason : Int -> String -> msg, decide : Int -> Bool -> msg } -> Active -> AuthState -> Url -> Model -> Html msg
page config active auth url model =
    pageHeading (title active.texts)
        (if not (allowed auth) then
            p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

         else
            div [ A.class "stack" ]
                [ form [ A.action "/registration_applications", A.method "get", A.class "card form-stack" ]
                    [ label []
                        [ input [ A.type_ "checkbox", A.name "unread_only", A.value "true", A.checked (Route.query "unread_only" url == "true") ] []
                        , text (T.unreviewedOnly active.texts)
                        ]
                    , button [ A.type_ "submit", A.class "filled-button" ] [ text (T.filter active.texts) ]
                    ]
                , viewFormProblem active.texts model.problem
                , if model.submitting then
                    p [ A.class "loading-state", A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

                  else
                    text ""
                , viewRemote config.retry
                    active.texts
                    model.requests
                    (\results ->
                        div [ A.class "stack" ]
                            [ if List.isEmpty results.items then
                                p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                              else
                                div [ A.class "stack" ] (List.map (applicationView config active model) results.items)
                            , viewPagination active.texts url results.prevPage results.nextPage
                            ]
                    )
                ]
        )


applicationView : { a | changeReason : Int -> String -> msg, decide : Int -> Bool -> msg } -> Active -> Model -> Application -> Html msg
applicationView config active model application =
    let
        reasonId =
            "application-reason-" ++ String.fromInt application.id
    in
    section [ A.class "card form-stack" ]
        [ p [] [ text (Domain.acctOf application.creator) ]
        , p [] [ text application.answer ]
        , p [] [ text application.publishedAt ]
        , case application.denyReason of
            Just reason ->
                p [] [ text reason ]

            Nothing ->
                text ""
        , label [ A.for reasonId ] [ text (T.reason active.texts) ]
        , textarea [ A.id reasonId, A.value (Dict.get application.id model.drafts |> Maybe.withDefault ""), Events.onInput (config.changeReason application.id) ] []
        , div [ A.class "actions" ]
            [ button [ A.type_ "button", A.disabled model.submitting, Events.onClick (config.decide application.id True) ] [ text (T.accept active.texts) ]
            , button [ A.type_ "button", A.disabled model.submitting, Events.onClick (config.decide application.id False) ] [ text (T.reject active.texts) ]
            ]
        ]
