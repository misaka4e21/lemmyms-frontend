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
    { users : Remote (Domain.Page Domain.LocalUserView), busy : Bool, problem : Maybe Api.Problem }


initial : Model
initial =
    { users = NotAsked, busy = False, problem = Nothing }


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


page : { retry : msg, changeAdmin : Int -> String -> Bool -> msg } -> Active -> AuthState -> Url -> Model -> Html msg
page config active auth url model =
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
                                        ul [ A.class "roster-list" ] (List.map (userView config active model.busy user.localUserView.person.id) results.items)
                                    , viewPagination active.texts url results.prevPage results.nextPage
                                    ]
                            )
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


userView : { a | changeAdmin : Int -> String -> Bool -> msg } -> Active -> Bool -> Int -> Domain.LocalUserView -> Html msg
userView config active busy ownId user =
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
            , A.disabled (busy || user.person.id == ownId)
            , Events.onClick (config.changeAdmin user.person.id (Domain.acctOf user.person) action)
            ]
            [ text
                (if action then
                    T.grantSiteAdmin active.texts

                 else
                    T.removeSiteAdmin active.texts
                )
            ]
        ]
