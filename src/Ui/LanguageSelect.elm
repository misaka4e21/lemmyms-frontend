module Ui.LanguageSelect exposing (view)

import Generated.I18n as T
import Html exposing (Html, button, details, div, input, label, p, span, summary, text)
import Html.Attributes as A
import Html.Events as Events
import Lemmy.Domain as Domain


view : { id : String, label : String, languages : List Domain.Language, selected : List Int, changed : Int -> Bool -> msg, retry : msg } -> T.I18n -> Html msg
view config texts =
    let
        knownIds =
            List.map .id config.languages

        selectedLabels =
            config.selected
                |> List.filterMap
                    (\id ->
                        config.languages
                            |> List.filter (\language -> language.id == id)
                            |> List.head
                            |> Maybe.map .name
                            |> Maybe.withDefault ("ID " ++ String.fromInt id)
                            |> Just
                    )

        options =
            List.map
                (\id ->
                    languageOption config id ("ID " ++ String.fromInt id)
                )
                (List.filter (\id -> not (List.member id knownIds)) config.selected)
                ++ List.map (\language -> languageOption config language.id language.name) config.languages

        selectionText =
            if List.isEmpty selectedLabels then
                ""

            else
                String.join ", " selectedLabels
    in
    div [ A.class "language-select" ]
        [ details [ A.class "language-select-disclosure" ]
            (if List.isEmpty config.languages then
                []

             else
                [ summary [ A.attribute "aria-label" config.label ]
                    [ span [] [ text config.label ]
                    , if String.isEmpty selectionText then
                        text ""

                      else
                        span [ A.class "language-select-summary" ] [ text selectionText ]
                    ]
                , div [ A.class "language-select-options" ] options
                ]
            )
        , if List.isEmpty config.languages then
            div [ A.class "language-select-unavailable" ]
                [ p [ A.attribute "role" "status" ] [ text (T.requestFailed texts) ]
                , button [ A.type_ "button", A.class "outlined-button", Events.onClick config.retry ] [ text (T.retryLabel texts) ]
                ]

          else
            text ""
        ]


languageOption : { a | id : String, languages : List Domain.Language, selected : List Int, changed : Int -> Bool -> msg } -> Int -> String -> Html msg
languageOption config id name =
    let
        inputId =
            config.id ++ "-language-" ++ String.fromInt id
    in
    label [ A.class "language-select-option", A.for inputId ]
        [ input
            [ A.id inputId
            , A.type_ "checkbox"
            , A.checked (List.member id config.selected)
            , A.disabled (List.isEmpty config.languages)
            , Events.onCheck (config.changed id)
            ]
            []
        , text name
        ]
