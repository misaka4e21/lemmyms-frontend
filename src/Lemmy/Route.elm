module Lemmy.Route exposing
    ( Route(..)
    , communityPostsUrl
    , cursor
    , cursorUrl
    , listing
    , modlogUrl
    , parse
    , path
    , postCommentsUrl
    , query
    , searchUrl
    , sort
    )

import AccountSource exposing (AccountContentSource(..))
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
    | EditComment Int
    | CreatePost (Maybe Int)
    | EditPost Int
    | CreateCommunity
    | Profile String
    | Search
    | Notifications
    | Settings
    | PasswordSettings
    | AccountContent AccountContentSource
    | AccountBlocks
    | Admin
    | Reports
    | Modlog (Maybe Int)
    | AdminBans
    | AdminSettings
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
        , Parser.map EditComment (s "comment" </> int </> s "edit")
        , Parser.map Comment (s "comment" </> int)
        , Parser.map (CreatePost Nothing) (s "create_post")
        , Parser.map CreateCommunity (s "create_community")
        , Parser.map Profile (s "u" </> string)
        , Parser.map Search (s "search")
        , Parser.map Notifications (s "notifications")
        , Parser.map PasswordSettings (s "settings" </> s "password")
        , Parser.map Settings (s "settings" </> s "profile")
        , Parser.map Settings (s "settings")
        , Parser.map (AccountContent SavedContent) (s "account" </> s "saved")
        , Parser.map (AccountContent ReadContent) (s "account" </> s "read")
        , Parser.map (AccountContent HiddenContent) (s "account" </> s "hidden")
        , Parser.map (AccountContent LikedContent) (s "account" </> s "liked")
        , Parser.map AccountBlocks (s "account" </> s "blocks")
        , Parser.map AdminBans (s "admin" </> s "bans")
        , Parser.map AdminSettings (s "admin" </> s "settings")
        , Parser.map Reports (s "admin" </> s "reports")
        , Parser.map (Modlog Nothing) (s "admin" </> s "modlog")
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
        Just (CreatePost Nothing) ->
            case String.toInt (query "post_id" url) of
                Just postId ->
                    EditPost postId

                Nothing ->
                    case String.toInt (query "community_id" url) of
                        Just communityId ->
                            CreatePost (Just communityId)

                        Nothing ->
                            CreatePost Nothing

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

        EditComment commentId ->
            Builder.absolute [ "comment", String.fromInt commentId, "edit" ] []

        CreatePost Nothing ->
            "/create_post"

        CreatePost (Just communityId) ->
            Builder.absolute [ "create_post" ] [ Builder.int "community_id" communityId ]

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

        PasswordSettings ->
            "/settings/password"

        AccountContent source ->
            "/account/"
                ++ (case source of
                        SavedContent ->
                            "saved"

                        ReadContent ->
                            "read"

                        HiddenContent ->
                            "hidden"

                        LikedContent ->
                            "liked"
                   )

        AccountBlocks ->
            "/account/blocks"

        Admin ->
            "/admin"

        Reports ->
            "/reports"

        Modlog Nothing ->
            "/modlog"

        Modlog (Just communityId) ->
            Builder.absolute [ "modlog", String.fromInt communityId ] []

        AdminBans ->
            "/admin/bans"

        AdminSettings ->
            "/admin/settings"

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


cursorUrl : Url -> String -> String
cursorUrl url cursorValue =
    url.path
        ++ Builder.toQuery
            ([ Builder.string "page_cursor" cursorValue ]
                ++ (if parse url == Search then
                        [ Builder.string "q" (query "q" url), Builder.string "kind" (query "kind" url) ]

                    else
                        []
                   )
                ++ optionalQuery "sort" url
                ++ optionalQuery "max_depth" url
                ++ optionalQuery "type" url
                ++ optionalQuery "state" url
                ++ optionalQuery "community_id" url
            )


optionalQuery : String -> Url -> List Builder.QueryParameter
optionalQuery name url =
    case query name url of
        "" ->
            []

        value ->
            [ Builder.string name value ]


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
