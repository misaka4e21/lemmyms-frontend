module Feature.SitePurge exposing (Model, initial, page, valid)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, button, form, input, label, option, p, select, text)
import Html.Attributes as A
import Html.Events as Events
import Lemmy.Domain as Domain
import Ui.Feedback exposing (loginRequired, viewFormProblem)
import Ui.Layout exposing (pageHeading)


type alias Model =
    { kind : String, target : String, reason : String, busy : Bool, problem : Maybe Api.Problem }


initial : Model
initial =
    { kind = "person", target = "", reason = "", busy = False, problem = Nothing }


valid : Model -> Bool
valid model =
    List.member model.kind [ "person", "community", "post", "comment" ]
        && validTarget model.target
        && not (String.isEmpty (String.trim model.reason))


validTarget : String -> Bool
validTarget value =
    String.toInt value |> Maybe.map (\id -> id > 0 && id <= 2147483647) |> Maybe.withDefault False


page : { change : String -> String -> msg, confirm : msg } -> Active -> AuthState -> Model -> Html msg
page config active auth model =
    pageHeading (T.purgeTitle active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    form [ A.class "card form-stack", Events.onSubmit config.confirm ]
                        [ p [] [ text (T.purgeHelp active.texts) ]
                        , label [ A.for "purge-kind" ] [ text (T.targetKind active.texts) ]
                        , select [ A.id "purge-kind", A.value model.kind, A.disabled model.busy, Events.onInput (config.change "kind") ]
                            [ option [ A.value "person" ] [ text (T.purgePerson active.texts) ]
                            , option [ A.value "community" ] [ text (T.purgeCommunity active.texts) ]
                            , option [ A.value "post" ] [ text (T.purgePost active.texts) ]
                            , option [ A.value "comment" ] [ text (T.purgeComment active.texts) ]
                            ]
                        , label [ A.for "purge-target" ] [ text (T.targetId active.texts) ]
                        , input
                            ([ A.id "purge-target", A.type_ "number", A.min "1", A.required True, A.disabled model.busy, A.value model.target, Events.onInput (config.change "target") ]
                                ++ (if not (String.isEmpty model.target) && not (validTarget model.target) then
                                        [ A.attribute "aria-invalid" "true", A.attribute "aria-describedby" "purge-target-error" ]

                                    else
                                        []
                                   )
                            )
                            []
                        , if not (String.isEmpty model.target) && not (validTarget model.target) then
                            p [ A.id "purge-target-error", A.class "field-error", A.attribute "role" "alert" ] [ text (T.invalidInput active.texts) ]

                          else
                            text ""
                        , label [ A.for "purge-reason" ] [ text (T.reason active.texts) ]
                        , input [ A.id "purge-reason", A.required True, A.disabled model.busy, A.value model.reason, Events.onInput (config.change "reason") ] []
                        , if model.busy then
                            p [ A.class "loading-state", A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

                          else
                            text ""
                        , viewFormProblem active.texts model.problem
                        , button [ A.id "purge-submit", A.type_ "submit", A.class "danger-button", A.disabled (model.busy || not (valid model)) ] [ text (T.purgeSubmit active.texts) ]
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )
