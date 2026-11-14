module Feature.SiteMedia exposing (Media, Model, decoder, initial, load, page)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, a, div, img, p, section, text)
import Html.Attributes as A
import Json.Decode as D
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias Media =
    { filename : String, publishedAt : String, person : Domain.Person }


type alias Model =
    Remote (Domain.Page Media)


initial : Model
initial =
    NotAsked


decoder : D.Decoder (Domain.Page Media)
decoder =
    Domain.page
        (D.map3 Media
            (D.at [ "local_image", "pictrs_alias" ] D.string)
            (D.at [ "local_image", "published_at" ] D.string)
            (D.field "person" Domain.person)
        )


load : AuthState -> Url -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth url loaded =
    case auth of
        Authenticated user ->
            if Domain.isAdmin user then
                ( Loading
                , Api.get
                    ("/image/list"
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


page : msg -> Active -> AuthState -> Url -> Model -> Html msg
page retry active auth url model =
    pageHeading (T.siteMedia active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    viewRemote retry
                        active.texts
                        model
                        (\results ->
                            div [ A.class "stack" ]
                                [ if List.isEmpty results.items then
                                    p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                                  else
                                    div [ A.class "stack" ] (List.map (mediaView active) results.items)
                                , viewPagination active.texts url results.prevPage results.nextPage
                                ]
                        )

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


mediaView : Active -> Media -> Html msg
mediaView active media =
    let
        imageUrl =
            Builder.absolute [ "api", "v4", "image", media.filename ] []
    in
    section [ A.class "card" ]
        [ a [ A.href imageUrl ] [ img [ A.src imageUrl, A.alt media.filename, A.width 100 ] [] ]
        , p [] [ text media.filename ]
        , p [] [ text (T.mediaUploadedBy (Domain.acctOf media.person) active.texts) ]
        , p [] [ text media.publishedAt ]
        ]
