module Lemmy.Markdown exposing (FileAttachment, excerpt, extractFileAttachments, render, renderer)

import Char
import Html exposing (Html)
import Html.Attributes as A
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Ui.Rich
import Url


type alias FileAttachment =
    { id : String, name : String, url : String }


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


excerpt : Int -> String -> ( String, Bool )
excerpt limit source =
    let
        plainText =
            case Markdown.Parser.parse source of
                Ok blocks ->
                    blocks |> List.concatMap blockText |> String.join " " |> String.words |> String.join " "

                Err _ ->
                    source |> String.words |> String.join " "

        characters =
            String.toList plainText

        shortened =
            List.length characters > limit
    in
    ( if shortened then
        List.take limit characters |> String.fromList |> String.trimRight |> (\value -> value ++ "…")

      else
        plainText
    , shortened
    )


blockText : Markdown.Block.Block -> List String
blockText block =
    case block of
        Markdown.Block.Heading _ inlines ->
            [ Markdown.Block.extractInlineText inlines ]

        Markdown.Block.Paragraph inlines ->
            [ Markdown.Block.extractInlineText inlines ]

        Markdown.Block.UnorderedList _ items ->
            List.concatMap (\(Markdown.Block.ListItem _ nested) -> List.concatMap blockText nested) items

        Markdown.Block.OrderedList _ _ items ->
            List.concatMap (List.concatMap blockText) items

        Markdown.Block.BlockQuote nested ->
            List.concatMap blockText nested

        Markdown.Block.Table headers rows ->
            List.map (.label >> Markdown.Block.extractInlineText) headers
                ++ List.concatMap (List.map Markdown.Block.extractInlineText) rows

        Markdown.Block.CodeBlock code ->
            [ code.body ]

        _ ->
            []


extractFileAttachments : String -> List FileAttachment
extractFileAttachments source =
    case Markdown.Parser.parse source of
        Ok blocks ->
            blocks
                |> List.concatMap extractBlock
                |> uniqueAttachments

        Err _ ->
            []


extractBlock : Markdown.Block.Block -> List FileAttachment
extractBlock block =
    case block of
        Markdown.Block.Heading _ inlines ->
            extractInlines inlines

        Markdown.Block.Paragraph inlines ->
            extractInlines inlines

        Markdown.Block.UnorderedList _ items ->
            List.concatMap
                (\(Markdown.Block.ListItem _ nested) -> List.concatMap extractBlock nested)
                items

        Markdown.Block.OrderedList _ _ items ->
            List.concatMap (List.concatMap extractBlock) items

        Markdown.Block.BlockQuote nested ->
            List.concatMap extractBlock nested

        Markdown.Block.Table header rows ->
            List.concatMap (.label >> extractInlines) header
                ++ List.concatMap (List.concatMap extractInlines) rows

        _ ->
            []


extractInlines : List Markdown.Block.Inline -> List FileAttachment
extractInlines inlines =
    List.concatMap extractInline inlines


extractInline : Markdown.Block.Inline -> List FileAttachment
extractInline inline =
    case inline of
        Markdown.Block.Link destination _ children ->
            let
                current =
                    fileAttachment destination (inlineText children)
            in
            Maybe.withDefault [] (Maybe.map List.singleton current)
                ++ extractInlines children

        Markdown.Block.Emphasis children ->
            extractInlines children

        Markdown.Block.Strong children ->
            extractInlines children

        Markdown.Block.Strikethrough children ->
            extractInlines children

        _ ->
            []


inlineText : List Markdown.Block.Inline -> String
inlineText inlines =
    inlines
        |> List.map
            (\inline ->
                case inline of
                    Markdown.Block.Text value ->
                        value

                    Markdown.Block.CodeSpan value ->
                        value

                    Markdown.Block.Link _ _ children ->
                        inlineText children

                    Markdown.Block.Emphasis children ->
                        inlineText children

                    Markdown.Block.Strong children ->
                        inlineText children

                    Markdown.Block.Strikethrough children ->
                        inlineText children

                    _ ->
                        ""
            )
        |> String.concat


fileAttachment : String -> String -> Maybe FileAttachment
fileAttachment destination label =
    if Ui.Rich.safeUrl destination then
        Url.fromString destination
            |> Maybe.andThen
                (\url ->
                    case String.split "/" url.path of
                        [ "", "api", "v4", "file", publicId, encodedFilename ] ->
                            if validUuid publicId then
                                Just
                                    { id = publicId
                                    , name =
                                        if String.isEmpty (String.trim label) then
                                            Url.percentDecode encodedFilename |> Maybe.withDefault "download"

                                        else
                                            label
                                    , url = destination
                                    }

                            else
                                Nothing

                        _ ->
                            Nothing
                )

    else
        Nothing


validUuid : String -> Bool
validUuid value =
    let
        isHex character =
            Char.isDigit character || (Char.toLower character >= 'a' && Char.toLower character <= 'f')

        validCharacter ( index, character ) =
            if List.member index [ 8, 13, 18, 23 ] then
                character == '-'

            else
                isHex character
    in
    String.length value
        == 36
        && (String.toList value |> List.indexedMap Tuple.pair |> List.all validCharacter)


uniqueAttachments : List FileAttachment -> List FileAttachment
uniqueAttachments attachments =
    List.foldl
        (\attachment result ->
            if List.any (\existing -> existing.id == attachment.id) result then
                result

            else
                result ++ [ attachment ]
        )
        []
        attachments


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
