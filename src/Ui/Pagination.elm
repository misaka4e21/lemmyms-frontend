module Ui.Pagination exposing (..)

import Generated.I18n as Translations
import Html exposing (Html, a, div, p, text)
import Html.Attributes as A
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Url exposing (Url)


viewPagination : Translations.I18n -> Url -> Maybe String -> Maybe String -> Html msg
viewPagination texts url previousCursor nextCursor =
    div [ A.class "pagination" ]
        [ case previousCursor of
            Just cursor ->
                a [ A.class "outlined-button", A.href (Route.cursorUrl url cursor) ]
                    [ text (Translations.previousPage texts) ]

            Nothing ->
                text ""
        , case nextCursor of
            Just cursor ->
                a [ A.class "outlined-button", A.href (Route.cursorUrl url cursor) ]
                    [ text (Translations.nextPage texts) ]

            Nothing ->
                text ""
        ]


emptyWithPagination : Translations.I18n -> Url -> Domain.Page a -> Html msg
emptyWithPagination texts url page =
    div [ A.class "stack" ]
        [ p [ A.class "empty-state" ] [ text (Translations.emptyLatest texts) ]
        , viewPagination texts url page.prevPage page.nextPage
        ]
