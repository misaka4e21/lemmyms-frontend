module Feature.SiteUsers exposing (Model, initial, load, page)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, button, div, form, input, label, li, option, p, select, text, ul)
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
    { users : Remote (Domain.Page Domain.LocalUserView)
    , busy : Bool
    , problem : Maybe Api.Problem
    , editingUsername : Maybe Int
    , usernameDraft : String
    , usernameBusy : Bool
    , usernameProblem : Maybe Api.Problem
    }


initial : Model
initial =
    { users = NotAsked
    , busy = False
    , problem = Nothing
    , editingUsername = Nothing
    , usernameDraft = ""
    , usernameBusy = False
    , usernameProblem = Nothing
    }


load : AuthState -> Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth url loaded =
    case auth of
        Authenticated user ->
            if Domain.isAdmin user then
                ( { initial | users = Loading }
                , Api.get
                    ("/admin/users"
                        ++ Builder.toQuery
                            ([ Builder.int "limit" 20
                             , Builder.string "sort" (sort url)
                             , Builder.string "banned_only"
                                (if Route.query "banned_only" url == "true" then
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
                    loaded
                )

            else
                ( initial, Cmd.none )

        _ ->
            ( initial, Cmd.none )


sort : Url -> String
sort url =
    if Route.query "sort" url == "old" then
        "old"

    else
        "new"


page : { retry : msg, changeAdmin : Int -> String -> Bool -> msg, editUsername : Int -> String -> msg, usernameChanged : String -> msg, saveUsername : Int -> msg, cancelUsername : msg } -> Bool -> Active -> AuthState -> Url -> Model -> Html msg
page config federationEnabled active auth url model =
    pageHeading (T.siteUsers active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    div [ A.class "stack" ]
                        [ form [ A.action "/admin/users", A.method "get", A.class "card form-stack" ]
                            [ label []
                                [ input [ A.type_ "checkbox", A.name "banned_only", A.value "true", A.checked (Route.query "banned_only" url == "true") ] []
                                , text (T.bannedUsersOnly active.texts)
                                ]
                            , label [ A.for "user-sort" ] [ text (T.filter active.texts) ]
                            , select [ A.id "user-sort", A.name "sort" ]
                                [ option [ A.value "new", A.selected (sort url == "new") ] [ text (T.sortNew active.texts) ]
                                , option [ A.value "old", A.selected (sort url == "old") ] [ text (T.sortOld active.texts) ]
                                ]
                            , button [ A.type_ "submit", A.class "filled-button" ] [ text (T.filter active.texts) ]
                            ]
                        , viewFormProblem active.texts model.problem
                        , viewRemote config.retry
                            active.texts
                            model.users
                            (\results ->
                                div [ A.class "stack" ]
                                    [ if List.isEmpty results.items then
                                        p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                                      else
                                        ul [ A.class "roster-list" ]
                                            (List.map
                                                (userView config active federationEnabled model user.localUserView.person.id)
                                                results.items
                                            )
                                    , viewPagination active.texts url results.prevPage results.nextPage
                                    ]
                            )
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


userView : { a | changeAdmin : Int -> String -> Bool -> msg, editUsername : Int -> String -> msg, usernameChanged : String -> msg, saveUsername : Int -> msg, cancelUsername : msg } -> Active -> Bool -> Model -> Int -> Domain.LocalUserView -> Html msg
userView config active federationEnabled model ownId user =
    let
        action =
            not user.localUser.admin
    in
    li []
        [ text (Domain.acctOf user.person)
        , if user.localUser.admin then
            text (" · " ++ T.siteAdministrator active.texts)

          else
            text ""
        , button
            [ A.id ("site-admin-" ++ String.fromInt user.person.id)
            , A.type_ "button"
            , A.disabled (model.busy || user.person.id == ownId)
            , Events.onClick (config.changeAdmin user.person.id (Domain.acctOf user.person) action)
            ]
            [ text
                (if action then
                    T.grantSiteAdmin active.texts

                 else
                    T.removeSiteAdmin active.texts
                )
            ]
        , if model.editingUsername == Just user.person.id then
            form [ A.class "form-stack", Events.onSubmit (config.saveUsername user.person.id) ]
                [ label [ A.for ("site-username-" ++ String.fromInt user.person.id) ] [ text (T.username active.texts) ]
                , input
                    [ A.id ("site-username-" ++ String.fromInt user.person.id)
                    , A.type_ "text"
                    , A.required True
                    , A.attribute "minlength" "2"
                    , A.attribute "maxlength" "20"
                    , A.attribute "aria-describedby" "site-username-help site-username-error"
                    , A.attribute "aria-invalid"
                        (if model.usernameProblem == Nothing then
                            "false"

                         else
                            "true"
                        )
                    , A.value model.usernameDraft
                    , Events.onInput config.usernameChanged
                    ]
                    []
                , p [ A.id "site-username-help", A.class "muted" ]
                    [ text
                        (if federationEnabled then
                            T.usernameRulesFederated active.texts

                         else
                            T.usernameRulesNonFederated active.texts
                        )
                    ]
                , Ui.Feedback.viewFormProblemWithId active.texts
                    "site-username-error"
                    (Maybe.map (Ui.Feedback.problemText active.texts) model.usernameProblem)
                , div [ A.class "actions wrap" ]
                    [ button [ A.type_ "submit", A.class "filled-button", A.disabled model.usernameBusy ] [ text (T.saveChanges active.texts) ]
                    , button [ A.type_ "button", A.class "outlined-button", A.disabled model.usernameBusy, Events.onClick config.cancelUsername ] [ text (T.cancel active.texts) ]
                    ]
                ]

          else
            button
                [ A.type_ "button"
                , A.class "text-button"
                , A.disabled model.usernameBusy
                , Events.onClick (config.editUsername user.person.id user.person.name)
                ]
                [ text (T.usernameChange active.texts) ]
        ]
