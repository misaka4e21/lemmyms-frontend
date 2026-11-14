module Feature.Taglines exposing (Model, initial, load, page)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict exposing (Dict)
import Generated.I18n as T
import Html exposing (Html, button, div, form, label, p, section, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias Model =
    { items : Remote (Domain.Page Domain.Tagline)
    , newContent : String
    , edits : Dict Int String
    , busy : Bool
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { items = NotAsked, newContent = "", edits = Dict.empty, busy = False, problem = Nothing }


load : AuthState -> Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth url loaded =
    case auth of
        Authenticated account ->
            if Domain.isAdmin account then
                ( { initial | items = Loading }
                , Api.get
                    ("/admin/tagline/list"
                        ++ Builder.toQuery
                            (Builder.int "limit" 20
                                :: (case Route.cursor url of
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


page : { retry : msg, newChanged : String -> msg, editChanged : Int -> String -> msg, create : msg, save : Int -> msg, delete : Int -> String -> msg } -> Active -> AuthState -> Url -> Model -> Html msg
page config active auth url model =
    pageHeading (T.taglines active.texts)
        (case auth of
            Authenticated account ->
                if Domain.isAdmin account then
                    div [ A.class "stack" ]
                        [ form [ A.class "card form-stack", Events.onSubmit config.create ]
                            [ label [ A.for "new-tagline" ] [ text (T.taglineContent active.texts) ]
                            , textarea [ A.id "new-tagline", A.required True, A.value model.newContent, Events.onInput config.newChanged ] []
                            , button [ A.type_ "submit", A.class "filled-button", A.disabled model.busy ] [ text (T.create active.texts) ]
                            , viewFormProblem active.texts model.problem
                            ]
                        , viewRemote config.retry
                            active.texts
                            model.items
                            (\results ->
                                div [ A.class "stack" ]
                                    [ if List.isEmpty results.items then
                                        p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                                      else
                                        div [ A.class "stack" ] (List.map (itemView config active model) results.items)
                                    , viewPagination active.texts url results.prevPage results.nextPage
                                    ]
                            )
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


itemView : { a | editChanged : Int -> String -> msg, save : Int -> msg, delete : Int -> String -> msg } -> Active -> Model -> Domain.Tagline -> Html msg
itemView config active model item =
    let
        identifier =
            String.fromInt item.id

        value =
            Dict.get item.id model.edits |> Maybe.withDefault item.content
    in
    section [ A.class "card form-stack" ]
        [ label [ A.for ("tagline-" ++ identifier) ] [ text (T.taglineContent active.texts) ]
        , textarea [ A.id ("tagline-" ++ identifier), A.value value, Events.onInput (config.editChanged item.id) ] []
        , div [ A.class "actions" ]
            [ button [ A.type_ "button", A.disabled (model.busy || String.isEmpty (String.trim value)), Events.onClick (config.save item.id) ] [ text (T.saveChanges active.texts) ]
            , button [ A.id ("tagline-delete-" ++ identifier), A.type_ "button", A.disabled model.busy, Events.onClick (config.delete item.id item.content) ] [ text (T.deleteTagline active.texts) ]
            ]
        ]
