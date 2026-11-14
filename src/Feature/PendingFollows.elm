module Feature.PendingFollows exposing (Model, allowed, initial, load, page)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, button, div, form, input, label, li, p, text, ul)
import Html.Attributes as A
import Html.Events as Events
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias Model =
    { requests : Remote (Domain.Page Domain.PendingFollowView)
    , submitting : Bool
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { requests = NotAsked, submitting = False, problem = Nothing }


allowed : AuthState -> Bool
allowed auth =
    case auth of
        Authenticated account ->
            Domain.isAdmin account || not (List.isEmpty account.moderates)

        _ ->
            False


load : AuthState -> Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth url response =
    if allowed auth then
        let
            all =
                case auth of
                    Authenticated account ->
                        Domain.isAdmin account && Route.query "all_communities" url == "true"

                    _ ->
                        False

            params =
                [ Builder.int "limit" 20
                , Builder.string "all_communities" (boolString all)
                , Builder.string "unread_only" (boolString (Route.query "unread_only" url == "true"))
                ]
                    ++ (case Route.cursor url of
                            Just cursor ->
                                [ Builder.string "page_cursor" cursor ]

                            Nothing ->
                                []
                       )
        in
        ( { initial | requests = Loading }, Api.get ("/community/pending_follows/list" ++ Builder.toQuery params) response )

    else
        ( initial, Cmd.none )


boolString : Bool -> String
boolString value =
    if value then
        "true"

    else
        "false"


page : { retry : msg, decide : Int -> Int -> Bool -> msg } -> Active -> AuthState -> Url -> Model -> Html msg
page config active auth url model =
    pageHeading (T.followRequests active.texts)
        (if not (allowed auth) then
            p [ A.class "empty-state" ] [ text (T.forbidden active.texts) ]

         else
            div [ A.class "stack" ]
                [ form [ A.action "/pending_follows", A.method "get", A.class "card form-stack" ]
                    ([ label []
                        [ input [ A.type_ "checkbox", A.name "unread_only", A.value "true", A.checked (Route.query "unread_only" url == "true") ] []
                        , text (T.unreviewedOnly active.texts)
                        ]
                     ]
                        ++ (case auth of
                                Authenticated account ->
                                    if Domain.isAdmin account then
                                        [ label []
                                            [ input [ A.type_ "checkbox", A.name "all_communities", A.value "true", A.checked (Route.query "all_communities" url == "true") ] []
                                            , text (T.allCommunities active.texts)
                                            ]
                                        ]

                                    else
                                        []

                                _ ->
                                    []
                           )
                        ++ [ button [ A.type_ "submit", A.class "filled-button" ] [ text (T.filter active.texts) ] ]
                    )
                , case model.problem of
                    Just _ ->
                        p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.requestFailed active.texts) ]

                    Nothing ->
                        text ""
                , viewRemote config.retry
                    active.texts
                    model.requests
                    (\results ->
                        div [ A.class "stack" ]
                            [ if List.isEmpty results.items then
                                p [ A.class "empty-state" ] [ text (T.noFollowRequests active.texts) ]

                              else
                                ul [ A.class "roster-list" ]
                                    (List.map
                                        (\item ->
                                            li []
                                                [ text (Domain.acctOf item.person ++ " · " ++ item.community.name)
                                                , button [ A.type_ "button", A.disabled model.submitting, Events.onClick (config.decide item.community.id item.person.id True) ] [ text (T.accept active.texts) ]
                                                , button [ A.type_ "button", A.disabled model.submitting, Events.onClick (config.decide item.community.id item.person.id False) ] [ text (T.reject active.texts) ]
                                                ]
                                        )
                                        results.items
                                    )
                            , viewPagination active.texts url results.prevPage results.nextPage
                            ]
                    )
                ]
        )
