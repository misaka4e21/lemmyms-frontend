module LemmyMarkdownTest exposing (suite)

import Html.Attributes as A
import Lemmy.Markdown as Markdown
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Lemmy Markdown rendering"
        [ test "keeps safe links and images" <|
            \_ ->
                Markdown.render "[site](https://example.test) ![alt](https://example.test/a.png)"
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "a", Selector.tag "img" ]
        , test "drops unsafe links" <|
            \_ ->
                Markdown.render "[click](javascript:alert(1))"
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.tag "a" ]
        , test "drops unsafe images" <|
            \_ ->
                Markdown.render "![alt](data:text/html,x)"
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.tag "img" ]
        , test "drops raw HTML" <|
            \_ ->
                Markdown.render "<script>alert(1)</script>"
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.tag "script" ]
        , test "renders safe link attributes" <|
            \_ ->
                Markdown.render "[site](https://example.test)"
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "a", Selector.attribute (A.href "https://example.test") ]
        ]
