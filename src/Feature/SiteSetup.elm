module Feature.SiteSetup exposing (Field(..), Model, body, change, initial, page)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, a, button, div, form, input, label, p, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Ui.Feedback exposing (loginRequired, viewFormProblem)
import Ui.Layout exposing (pageHeading)


type Field
    = Name
    | Summary
    | Sidebar
    | Legal


type alias Model =
    { name : String
    , summary : String
    , sidebar : String
    , legal : String
    , submitting : Bool
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { name = "", summary = "", sidebar = "", legal = "", submitting = False, problem = Nothing }


change : Field -> String -> Model -> Model
change field value model =
    case field of
        Name ->
            { model | name = value }

        Summary ->
            { model | summary = value }

        Sidebar ->
            { model | sidebar = value }

        Legal ->
            { model | legal = value }


body : Model -> String
body model =
    Encode.object
        ([ ( "name", Encode.string (String.trim model.name) ) ]
            ++ optional "summary" model.summary
            ++ optional "sidebar" model.sidebar
            ++ optional "legal_information" model.legal
        )
        |> Encode.encode 0


optional : String -> String -> List ( String, Encode.Value )
optional field value =
    if String.isEmpty (String.trim value) then
        []

    else
        [ ( field, Encode.string value ) ]


page : { change : Field -> String -> msg, submit : msg } -> Active -> AuthState -> Maybe Domain.SiteView -> Model -> Html msg
page config active auth site model =
    pageHeading (T.siteSetup active.texts)
        (case site of
            Nothing ->
                p [ A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

            Just current ->
                if current.localSite.siteSetup then
                    div [ A.class "card" ]
                        [ p [] [ text (T.siteSetupComplete active.texts) ]
                        , a [ A.href (Route.path Route.Home), A.class "outlined-button" ] [ text (T.navLatest active.texts) ]
                        ]

                else
                    case auth of
                        CheckingSession ->
                            p [ A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

                        Anonymous ->
                            loginRequired active.texts

                        Authenticated identity ->
                            if Domain.isAdmin identity then
                                form [ Events.onSubmit config.submit, A.class "card form-stack" ]
                                    [ label [ A.for "site-name" ] [ text (T.siteName active.texts) ]
                                    , input [ A.id "site-name", A.required True, A.value model.name, Events.onInput (config.change Name) ] []
                                    , label [ A.for "site-summary" ] [ text (T.communitySummary active.texts) ]
                                    , textarea [ A.id "site-summary", A.value model.summary, Events.onInput (config.change Summary) ] []
                                    , label [ A.for "site-sidebar" ] [ text (T.communitySidebar active.texts) ]
                                    , textarea [ A.id "site-sidebar", A.value model.sidebar, Events.onInput (config.change Sidebar) ] []
                                    , label [ A.for "site-legal" ] [ text (T.legalInformation active.texts) ]
                                    , textarea [ A.id "site-legal", A.value model.legal, Events.onInput (config.change Legal) ] []
                                    , viewFormProblem active.texts model.problem
                                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.submitting ] [ text (T.saveChanges active.texts) ]
                                    ]

                            else
                                p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]
        )
