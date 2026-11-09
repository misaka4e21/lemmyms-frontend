module LemmyRouteTest exposing (suite)

import Expect
import Lemmy.Route as Route
import Test exposing (Test, describe, test)
import Url


parse : String -> Route.Route
parse value =
    Url.fromString ("https://forum.test" ++ value)
        |> Maybe.map Route.parse
        |> Maybe.withDefault Route.NotFound


suite : Test
suite =
    describe "Lemmy canonical routes"
        [ test "parses canonical paths" <|
            \_ ->
                Expect.equal
                    [ Route.Home
                    , Route.Communities
                    , Route.Community "news"
                    , Route.CommunitySettings "news"
                    , Route.Post 10 Nothing
                    , Route.Post 10 (Just 20)
                    , Route.Comment 20
                    , Route.CreatePost
                    , Route.CreateCommunity
                    , Route.Profile "alice"
                    , Route.Search
                    , Route.Notifications
                    , Route.Settings
                    , Route.Admin
                    , Route.Reports
                    , Route.Modlog Nothing
                    , Route.Modlog (Just 2)
                    , Route.Login
                    , Route.Register
                    , Route.VerifyEmail "token"
                    , Route.PasswordChange "token"
                    , Route.LoginReset
                    ]
                    (List.map parse
                        [ "/"
                        , "/communities"
                        , "/c/news"
                        , "/c/news/settings"
                        , "/post/10"
                        , "/post/10/20"
                        , "/comment/20"
                        , "/create_post"
                        , "/create_community"
                        , "/u/alice"
                        , "/search"
                        , "/notifications"
                        , "/settings"
                        , "/admin"
                        , "/reports"
                        , "/modlog"
                        , "/modlog/2"
                        , "/login"
                        , "/signup"
                        , "/verify_email/token"
                        , "/password_change/token"
                        , "/login_reset"
                        ]
                    )
        , test "round trips path builders" <|
            \_ ->
                let
                    routes =
                        [ Route.Home
                        , Route.Communities
                        , Route.Community "news"
                        , Route.CommunitySettings "news"
                        , Route.Post 10 Nothing
                        , Route.Post 10 (Just 20)
                        , Route.Comment 20
                        , Route.CreatePost
                        , Route.EditPost 10
                        , Route.CreateCommunity
                        , Route.Profile "alice"
                        , Route.Search
                        , Route.Notifications
                        , Route.Settings
                        , Route.Admin
                        , Route.Reports
                        , Route.Modlog Nothing
                        , Route.Modlog (Just 2)
                        , Route.Login
                        , Route.Register
                        , Route.VerifyEmail "token"
                        , Route.PasswordChange "token"
                        , Route.LoginReset
                        ]
                in
                Expect.equal routes (List.map (Route.path >> parse) routes)
        , test "reads cursor, sort, and listing query state" <|
            \_ ->
                Url.fromString "https://forum.test/c/news?type=local&sort=top&page_cursor=abc"
                    |> Maybe.map
                        (\url ->
                            ( Route.cursor url
                            , Route.sort "active" url
                            , Route.listing "local" url
                            )
                        )
                    |> Maybe.withDefault ( Nothing, "", "" )
                    |> Expect.equal ( Just "abc", "top", "local" )
        , test "builds community and search URLs with cursors" <|
            \_ ->
                Expect.equal
                    [ "/c/news?type=local&sort=top&page_cursor=abc"
                    , "/search?kind=posts&q=news&page_cursor=next"
                    , "/post/10?sort=top&max_depth=4&page_cursor=next"
                    ]
                    [ Route.communityPostsUrl "news" "local" "top" (Just "abc")
                    , Route.searchUrl "posts" "news" (Just "next")
                    , Route.postCommentsUrl 10 "top" 4 (Just "next")
                    ]
        ]
