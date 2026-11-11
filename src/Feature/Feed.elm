module Feature.Feed exposing (Config, Model, Msg(..), initial, load, pageLatest, update)

import Api
import App.Context exposing (Active)
import Generated.I18n as Translations
import Html exposing (Html, div)
import Html.Attributes as A
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { topics : Remote (Domain.Page Domain.PostView)
    }


initial : Model
initial =
    { topics = NotAsked }


type Msg
    = Loaded Api.Response


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


update : Msg -> Model -> ( Model, Maybe Api.Problem )
update message model =
    case message of
        Loaded response ->
            case Api.decodeResponse (Domain.page Domain.postView) response of
                Ok page ->
                    ( { topics = Ready page }, Nothing )

                Err problem ->
                    ( { topics = Failed problem }, sessionProblem problem )


load : Url -> ( Model, Cmd Msg )
load url =
    ( { topics = Loading }
    , Api.get ("/post/list?type=local&sort=active&limit=20" ++ cursorQuery url) Loaded
    )


cursorQuery : Url -> String
cursorQuery url =
    case Route.cursor url of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


type alias Config msg =
    { retry : msg
    , postCard : Domain.PostView -> Html msg
    }


type alias ViewModel =
    { topics : Remote (Domain.Page Domain.PostView)
    , url : Url
    }


pageLatest : Config msg -> ViewModel -> Active -> Html msg
pageLatest config model active =
    pageHeading (Translations.latestTitle active.texts)
        (viewRemote config.retry
            active.texts
            model.topics
            (\page ->
                if List.isEmpty page.items then
                    emptyWithPagination active.texts model.url page

                else
                    div [ A.class "stack" ]
                        [ div [ A.class "stack" ] (List.map config.postCard page.items)
                        , viewPagination active.texts model.url page.prevPage page.nextPage
                        ]
            )
        )
