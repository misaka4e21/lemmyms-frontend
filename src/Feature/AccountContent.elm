module Feature.AccountContent exposing (Config, Model, Msg(..), initial, load, pageAccountContent, reset, update)

import AccountSource exposing (AccountContentSource(..))
import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as Translations
import Html exposing (Html, div, p, text)
import Html.Attributes as A
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { posts : Remote (Domain.Page Domain.PostView) }


initial : Model
initial =
    { posts = NotAsked }


reset : Model -> Model
reset model =
    { model | posts = NotAsked }


type Msg
    = Loaded Api.Response


update : Msg -> Model -> ( Model, Maybe Api.Problem )
update message model =
    case message of
        Loaded response ->
            case Api.decodeResponse (Domain.page Domain.postView) response of
                Ok page ->
                    ( { model | posts = Ready page }, Nothing )

                Err problem ->
                    ( { model | posts = Failed problem }
                    , if problem.status == 401 then
                        Just problem

                      else
                        Nothing
                    )


sourceName : AccountContentSource -> String
sourceName source =
    case source of
        SavedContent ->
            "saved"

        ReadContent ->
            "read"

        HiddenContent ->
            "hidden"

        LikedContent ->
            "liked"


load : AccountContentSource -> Url -> Model -> ( Model, Cmd Msg )
load source url model =
    ( { model | posts = Loading }
    , Api.get
        ("/account/"
            ++ sourceName source
            ++ "?limit=20"
            ++ cursorQuery url
        )
        Loaded
    )


cursorQuery : Url -> String
cursorQuery url =
    case Route.cursor url of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


sourceTitle : Translations.I18n -> AccountContentSource -> String
sourceTitle texts source =
    case source of
        SavedContent ->
            Translations.savedPostsTitle texts

        ReadContent ->
            Translations.readPostsTitle texts

        HiddenContent ->
            Translations.hiddenPostsTitle texts

        LikedContent ->
            Translations.likedPostsTitle texts


type alias Config msg =
    { retry : msg
    , postCard : Domain.PostView -> Html msg
    }


type alias ViewModel =
    { posts : Remote (Domain.Page Domain.PostView)
    , auth : AuthState
    , url : Url
    }


pageAccountContent : Config msg -> ViewModel -> Active -> AccountContentSource -> Html msg
pageAccountContent config model active source =
    pageHeading (sourceTitle active.texts source)
        (case model.auth of
            Authenticated _ ->
                div [ A.class "stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.accountContentIntro active.texts) ]
                    , viewRemote config.retry
                        active.texts
                        model.posts
                        (\page ->
                            if List.isEmpty page.items then
                                emptyWithPagination active.texts model.url page

                            else
                                div [ A.class "stack" ]
                                    [ div [ A.class "stack" ] (List.map config.postCard page.items)
                                    , viewPagination active.texts model.url page.prevPage page.nextPage
                                    ]
                        )
                    ]

            _ ->
                loginRequired active.texts
        )
