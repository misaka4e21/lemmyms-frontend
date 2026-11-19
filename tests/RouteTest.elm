module RouteTest exposing (suite)

import AccountSource exposing (AccountContentSource(..))
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
    describe "canonical Lemmy routes"
        [ test "parses canonical and application paths" <|
            \_ ->
                Expect.equal
                    [ Route.Home
                    , Route.Communities
                    , Route.Community "news"
                    , Route.CommunitySettings "news"
                    , Route.Post 10 Nothing
                    , Route.Post 10 (Just 20)
                    , Route.Comment 20
                    , Route.EditComment 20
                    , Route.CreatePost Nothing
                    , Route.CreatePost (Just 2)
                    , Route.EditPost 10
                    , Route.CreateCommunity
                    , Route.CreatePrivateMessage 1
                    , Route.MultiCommunities
                    , Route.CreateMultiCommunity
                    , Route.MultiCommunity "news"
                    , Route.MultiCommunitySettings "news"
                    , Route.Profile "alice"
                    , Route.Search
                    , Route.Notifications
                    , Route.Settings
                    , Route.Settings
                    , Route.PasswordSettings
                    , Route.AccountContent SavedContent
                    , Route.AccountContent ReadContent
                    , Route.AccountContent HiddenContent
                    , Route.AccountContent LikedContent
                    , Route.AccountBlocks
                    , Route.Admin
                    , Route.Reports
                    , Route.Modlog Nothing
                    , Route.Modlog (Just 2)
                    , Route.Reports
                    , Route.Modlog Nothing
                    , Route.AdminBans
                    , Route.AdminSettings
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
                        , "/comment/20/edit"
                        , "/create_post"
                        , "/create_post?community_id=2"
                        , "/create_post?post_id=10"
                        , "/create_community"
                        , "/create_private_message/1"
                        , "/multi_communities"
                        , "/create_multi_community"
                        , "/m/news"
                        , "/m/news/settings"
                        , "/u/alice"
                        , "/search"
                        , "/notifications"
                        , "/settings"
                        , "/settings/profile"
                        , "/settings/password"
                        , "/account/saved"
                        , "/account/read"
                        , "/account/hidden"
                        , "/account/liked"
                        , "/account/blocks"
                        , "/admin"
                        , "/reports"
                        , "/modlog"
                        , "/modlog/2"
                        , "/admin/reports"
                        , "/admin/modlog"
                        , "/admin/bans"
                        , "/admin/settings"
                        , "/login"
                        , "/signup"
                        , "/verify_email/token"
                        , "/password_change/token"
                        , "/login_reset"
                        ]
                    )
        , test "round trips the legal route" <|
            \_ ->
                Expect.equal Route.Legal (parse (Route.path Route.Legal))
        , test "round trips the instances route" <|
            \_ ->
                Expect.equal Route.Instances (parse (Route.path Route.Instances))
        , test "round trips the external interaction route" <|
            \_ ->
                Expect.equal Route.ExternalInteraction (parse (Route.path Route.ExternalInteraction))
        , test "round trips P4 administration and authentication paths" <|
            \_ ->
                let
                    routes =
                        [ Route.Setup
                        , Route.RegistrationApplications
                        , Route.PendingFollows
                        , Route.AdminTaglines
                        , Route.AdminEmoji
                        , Route.AdminOAuthProviders
                        , Route.AdminUsers
                        , Route.AdminMedia
                        , Route.AdminPurge
                        , Route.AdminConfiguration
                        , Route.AdminFederation
                        , Route.OAuthCallback
                        ]
                in
                Expect.equal routes (List.map (Route.path >> parse) routes)
        , test "round trips generated paths" <|
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
                        , Route.EditComment 20
                        , Route.CreatePost Nothing
                        , Route.CreatePost (Just 2)
                        , Route.EditPost 10
                        , Route.CreateCommunity
                        , Route.CreatePrivateMessage 1
                        , Route.MultiCommunities
                        , Route.CreateMultiCommunity
                        , Route.MultiCommunity "news"
                        , Route.MultiCommunitySettings "news"
                        , Route.Profile "alice"
                        , Route.Search
                        , Route.Notifications
                        , Route.Settings
                        , Route.PasswordSettings
                        , Route.AccountContent SavedContent
                        , Route.AccountContent ReadContent
                        , Route.AccountContent HiddenContent
                        , Route.AccountContent LikedContent
                        , Route.AccountBlocks
                        , Route.Admin
                        , Route.Reports
                        , Route.Modlog Nothing
                        , Route.Modlog (Just 2)
                        , Route.AdminBans
                        , Route.AdminSettings
                        , Route.Login
                        , Route.Register
                        , Route.VerifyEmail "token"
                        , Route.PasswordChange "token"
                        , Route.LoginReset
                        ]
                in
                Expect.equal routes (List.map (Route.path >> parse) routes)
        , test "rejects former Commune paths" <|
            \_ ->
                Expect.equal
                    (List.repeat 8 Route.NotFound)
                    (List.map parse
                        [ "/communities/1"
                        , "/communities/1/manage"
                        , "/posts/1"
                        , "/posts/1/edit"
                        , "/profiles/alice"
                        , "/register"
                        , "/verify-email"
                        , "/reset-password"
                        ]
                    )
        , test "decodes percent-encoded dynamic route segments once" <|
            \_ ->
                Expect.equal
                    [ Route.Profile "凌子卿"
                    , Route.Profile "%E5%87%8C"
                    , Route.Community "凌子卿"
                    , Route.MultiCommunity "凌子卿"
                    ]
                    (List.map parse
                        [ "/u/%E5%87%8C%E5%AD%90%E5%8D%BF"
                        , "/u/%25E5%2587%258C"
                        , "/c/%E5%87%8C%E5%AD%90%E5%8D%BF"
                        , "/m/%E5%87%8C%E5%AD%90%E5%8D%BF"
                        ]
                    )
        , test "encodes dynamic route segments for one decode on navigation" <|
            \_ ->
                Expect.equal
                    [ "/u/%E5%87%8C%E5%AD%90%E5%8D%BF"
                    , "/c/%E5%87%8C%E5%AD%90%E5%8D%BF"
                    , "/m/%E5%87%8C%E5%AD%90%E5%8D%BF"
                    ]
                    [ Route.path (Route.Profile "凌子卿")
                    , Route.path (Route.Community "凌子卿")
                    , Route.path (Route.MultiCommunity "凌子卿")
                    ]
        , test "encodes the decoded profile handle once for a person query" <|
            \_ ->
                let
                    personHandle path =
                        case parse path of
                            Route.Profile username ->
                                Url.percentEncode username

                            _ ->
                                ""
                in
                Expect.equal
                    [ "%E5%87%8C%E5%AD%90%E5%8D%BF"
                    , "%25E5%2587%258C"
                    ]
                    [ personHandle "/u/%E5%87%8C%E5%AD%90%E5%8D%BF"
                    , personHandle "/u/%25E5%2587%258C"
                    ]
        , test "reads cursor, sort, and listing state" <|
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
        , test "builds cursor URLs without losing context" <|
            \_ ->
                Expect.equal
                    [ "/c/news?page_cursor=next&sort=top&type=local"
                    , "/search?page_cursor=next&q=news&kind=posts"
                    , "/post/10?page_cursor=next&sort=top&max_depth=4"
                    ]
                    [ Url.fromString "https://forum.test/c/news?type=local&sort=top"
                        |> Maybe.map (\url -> Route.cursorUrl url "next")
                        |> Maybe.withDefault ""
                    , Url.fromString "https://forum.test/search?q=news&kind=posts"
                        |> Maybe.map (\url -> Route.cursorUrl url "next")
                        |> Maybe.withDefault ""
                    , Url.fromString "https://forum.test/post/10?sort=top&max_depth=4"
                        |> Maybe.map (\url -> Route.cursorUrl url "next")
                        |> Maybe.withDefault ""
                    ]
        , test "builds collection URLs" <|
            \_ ->
                Expect.equal
                    [ "/c/news?type=local&sort=top&page_cursor=abc"
                    , "/search?kind=posts&q=news&page_cursor=next"
                    , "/post/10?sort=top&max_depth=4"
                    , "/post/10?sort=top&max_depth=4&page_cursor=next"
                    , "/modlog/2?page_cursor=next"
                    ]
                    [ Route.communityPostsUrl "news" "local" "top" (Just "abc")
                    , Route.searchUrl "posts" "news" (Just "next")
                    , Route.postCommentsUrl 10 "top" 4 Nothing
                    , Route.postCommentsUrl 10 "top" 4 (Just "next")
                    , Route.modlogUrl (Just 2) (Just "next")
                    ]
        , test "does not generate an offset parameter" <|
            \_ ->
                let
                    url =
                        Url.fromString "https://forum.test/post/10?sort=top&max_depth=4&offset=40"
                            |> Maybe.withDefault (Url.fromString "https://forum.test/" |> Maybe.withDefault { protocol = Url.Https, host = "forum.test", port_ = Nothing, path = "/", query = Nothing, fragment = Nothing })
                in
                Expect.equal False (String.contains "offset" (Route.postCommentsUrl 10 (Route.query "sort" url) 4 (Route.cursor url)))
        , test "replaces one query parameter and drops the cursor" <|
            \_ ->
                let
                    url =
                        Url.fromString "https://forum.test/c/news?type=local&sort=top&page_cursor=abc&view=card"
                            |> Maybe.withDefault (Url.fromString "https://forum.test/" |> Maybe.withDefault { protocol = Url.Https, host = "forum.test", port_ = Nothing, path = "/", query = Nothing, fragment = Nothing })
                in
                Expect.equal
                    [ "/c/news?type=local&view=card&sort=new"
                    , "/c/news?type=local&sort=top"
                    ]
                    [ Route.withQuery "sort" "new" url
                    , Route.withQuery "view" "" url
                    ]
        ]
