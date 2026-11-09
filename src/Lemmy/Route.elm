module Lemmy.Route exposing (Route(..), communityPostsUrl, cursor, listing, modlogUrl, parse, path, postCommentsUrl, query, searchUrl, sort)

import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), Parser, int, s, string, top)


type Route
    = Home
    | Communities
    | Community String
    | CommunitySettings String
    | Post Int (Maybe Int)
    | Comment Int
    | CreatePost
    | EditPost Int
    | CreateCommunity
    | Profile String
    | Search
    | Notifications
    | Settings
    | Admin
    | Reports
    | Modlog (Maybe Int)
    | Login
    | Register
    | VerifyEmail String
    | PasswordChange String
    | LoginReset
    | NotFound


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home top
        , Parser.map CommunitySettings (s "c" </> string </> s "settings")
        , Parser.map Community (s "c" </> string)
        , Parser.map Communities (s "communities")
        , Parser.map (\postId commentId -> Post postId (Just commentId)) (s "post" </> int </> int)
        , Parser.map (\postId -> Post postId Nothing) (s "post" </> int)
        , Parser.map Comment (s "comment" </> int)
        , Parser.map CreatePost (s "create_post")
        , Parser.map CreateCommunity (s "create_community")
        , Parser.map Profile (s "u" </> string)
        , Parser.map Search (s "search")
        , Parser.map Notifications (s "notifications")
        , Parser.map Settings (s "settings")
        , Parser.map Admin (s "admin")
        , Parser.map Reports (s "reports")
        , Parser.map (\communityId -> Modlog (Just communityId)) (s "modlog" </> int)
        , Parser.map (Modlog Nothing) (s "modlog")
        , Parser.map Login (s "login")
        , Parser.map Register (s "signup")
        , Parser.map VerifyEmail (s "verify_email" </> string)
        , Parser.map PasswordChange (s "password_change" </> string)
        , Parser.map LoginReset (s "login_reset")
        ]


parse : Url -> Route
parse url =
    case Parser.parse parser url of
        Just CreatePost ->
            case String.toInt (query "post_id" url) of
                Just postId ->
                    EditPost postId

                Nothing ->
                    CreatePost

        Just route ->
            route

        Nothing ->
            NotFound


path : Route -> String
path route =
    case route of
        Home ->
            "/"

        Communities ->
            "/communities"

        Community name ->
            Builder.absolute [ "c", name ] []

        CommunitySettings name ->
            Builder.absolute [ "c", name, "settings" ] []

        Post postId Nothing ->
            Builder.absolute [ "post", String.fromInt postId ] []

        Post postId (Just commentId) ->
            Builder.absolute [ "post", String.fromInt postId, String.fromInt commentId ] []

        Comment commentId ->
            Builder.absolute [ "comment", String.fromInt commentId ] []

        CreatePost ->
            "/create_post"

        EditPost postId ->
            Builder.absolute [ "create_post" ] [ Builder.int "post_id" postId ]

        CreateCommunity ->
            "/create_community"

        Profile username ->
            Builder.absolute [ "u", username ] []

        Search ->
            "/search"

        Notifications ->
            "/notifications"

        Settings ->
            "/settings"

        Admin ->
            "/admin"

        Reports ->
            "/reports"

        Modlog Nothing ->
            "/modlog"

        Modlog (Just communityId) ->
            Builder.absolute [ "modlog", String.fromInt communityId ] []

        Login ->
            "/login"

        Register ->
            "/signup"

        VerifyEmail token ->
            Builder.absolute [ "verify_email", token ] []

        PasswordChange token ->
            Builder.absolute [ "password_change", token ] []

        LoginReset ->
            "/login_reset"

        NotFound ->
            "/404"


query : String -> Url -> String
query name url =
    url.query
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.filterMap
            (\part ->
                case String.split "=" part of
                    key :: values ->
                        if key == name then
                            Just (Url.percentDecode (String.replace "+" " " (String.join "=" values)) |> Maybe.withDefault "")

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head
        |> Maybe.withDefault ""


cursor : Url -> Maybe String
cursor url =
    case query "page_cursor" url of
        "" ->
            Nothing

        value ->
            Just value


sort : String -> Url -> String
sort fallback url =
    case query "sort" url of
        "" ->
            fallback

        value ->
            value


listing : String -> Url -> String
listing fallback url =
    case query "type" url of
        "" ->
            fallback

        value ->
            value


communityPostsUrl : String -> String -> String -> Maybe String -> String
communityPostsUrl name listingValue sortValue cursorValue =
    Builder.absolute [ "c", name ] (pagingQuery listingValue sortValue cursorValue)


postCommentsUrl : Int -> String -> Int -> Maybe String -> String
postCommentsUrl postId sortValue maxDepth cursorValue =
    Builder.absolute [ "post", String.fromInt postId ]
        (Builder.string "sort" sortValue
            :: Builder.int "max_depth" (clamp 1 8 maxDepth)
            :: cursorQuery cursorValue
        )


searchUrl : String -> String -> Maybe String -> String
searchUrl kind searchTerm cursorValue =
    Builder.absolute [ "search" ]
        (Builder.string "kind" kind
            :: Builder.string "q" searchTerm
            :: cursorQuery cursorValue
        )


modlogUrl : Maybe Int -> Maybe String -> String
modlogUrl communityId cursorValue =
    (case communityId of
        Just id ->
            Builder.absolute [ "modlog", String.fromInt id ] []

        Nothing ->
            "/modlog"
    )
        ++ Builder.toQuery (cursorQuery cursorValue)


pagingQuery : String -> String -> Maybe String -> List Builder.QueryParameter
pagingQuery listingValue sortValue cursorValue =
    [ Builder.string "type" listingValue
    , Builder.string "sort" sortValue
    ]
        ++ cursorQuery cursorValue


cursorQuery : Maybe String -> List Builder.QueryParameter
cursorQuery cursorValue =
    case cursorValue of
        Just value ->
            [ Builder.string "page_cursor" value ]

        Nothing ->
            []
