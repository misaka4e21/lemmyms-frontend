module Lemmy.Markdown exposing (render, renderer)

import Html exposing (Html)
import Html.Attributes as A
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Ui.Rich


renderer : Markdown.Renderer.Renderer (Html msg)
renderer =
    let
        base =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { base
        | link = renderLink
        , image = renderImage
        , html = Markdown.Html.oneOf []
    }


render : String -> Html msg
render source =
    case Markdown.Parser.parse source of
        Ok blocks ->
            case Markdown.Renderer.render renderer blocks of
                Ok rendered ->
                    Html.div [ A.class "rich", A.dir "auto" ] rendered

                Err _ ->
                    fallback source

        Err _ ->
            fallback source


renderLink : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg
renderLink link children =
    if Ui.Rich.safeUrl link.destination then
        Html.a
            ([ A.href link.destination
             , A.rel "noopener noreferrer"
             ]
                ++ (case link.title of
                        Just title ->
                            [ A.title title ]

                        Nothing ->
                            []
                   )
            )
            children

    else
        Html.span [] children


renderImage : { alt : String, src : String, title : Maybe String } -> Html msg
renderImage image =
    if Ui.Rich.safeUrl image.src then
        Html.img
            ([ A.src image.src
             , A.alt image.alt
             , A.attribute "loading" "lazy"
             , A.attribute "referrerpolicy" "no-referrer"
             ]
                ++ (case image.title of
                        Just title ->
                            [ A.title title ]

                        Nothing ->
                            []
                   )
            )
            []

    else
        Html.span [] [ Html.text image.alt ]


fallback : String -> Html msg
fallback source =
    Html.div [ A.class "rich", A.dir "auto" ] [ Html.text source ]
