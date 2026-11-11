module LemmyDomainTest exposing (suite)

import Expect
import Json.Decode as Decode
import Lemmy.CommentTree as CommentTree
import Lemmy.Domain as Domain
import Lemmy.Pagination as Pagination
import Lemmy.Permissions as Permissions
import Lemmy.Problem as Problem
import LemmyFixtures as Fixtures
import Test exposing (Test, describe, test)


decode : Decode.Decoder a -> String -> Result Decode.Error a
decode decoder value =
    Decode.decodeString decoder value


suite : Test
suite =
    describe "Lemmy v4 domain"
        [ test "decodes site and local-site fields" <|
            \_ ->
                Expect.equal (Ok { name = "Forum", hostname = "forum.test", mode = Domain.OpenRegistration, federation = True })
                    (decode Domain.getSiteResponse Fixtures.siteJson
                        |> Result.map
                            (\response ->
                                { name = response.siteView.site.name
                                , hostname = response.siteView.localSite.hostname
                                , mode = response.siteView.localSite.registrationMode
                                , federation = response.siteView.localSite.federationEnabled
                                }
                            )
                    )
        , test "decodes account and viewer identity" <|
            \_ ->
                Expect.equal (Ok ( "alice", False, True ))
                    (decode Domain.myUserInfo Fixtures.myUserJson
                        |> Result.map
                            (\user ->
                                ( user.localUserView.person.name
                                , user.localUserView.localUser.admin
                                , user.localUserView.localUser.emailVerified
                                )
                            )
                    )
        , test "decodes post view counters and actions" <|
            \_ ->
                Expect.equal (Ok { score = 2, upvotes = 3, downvotes = 1, vote = Just True, creator = True })
                    (decode Domain.postView Fixtures.postViewJson
                        |> Result.map
                            (\view ->
                                { score = view.post.score
                                , upvotes = view.post.upvotes
                                , downvotes = view.post.downvotes
                                , vote = Maybe.andThen .voteIsUpvote view.postActions
                                , creator = view.post.creatorId == 1
                                }
                            )
                    )
        , test "decodes comment path and comment view" <|
            \_ ->
                Expect.equal (Ok ( "0.20", 0, True ))
                    (decode Domain.commentView Fixtures.commentViewJson
                        |> Result.map
                            (\view ->
                                ( view.comment.path
                                , view.comment.childCount
                                , view.comment.postId == 10
                                )
                            )
                    )
        , test "decodes search results and cursor" <|
            \_ ->
                Expect.equal (Ok ( 1, 1, Just "next-cursor" ))
                    (decode Domain.searchResponse Fixtures.searchJson
                        |> Result.map
                            (\response ->
                                ( List.length response.posts
                                , List.length response.communities
                                , response.nextPage
                                )
                            )
                    )
        , test "decodes image upload response" <|
            \_ ->
                Expect.equal (Ok ( "https://forum.test/pictrs/image/abc.png", "abc.png" ))
                    (decode Domain.imageUpload Fixtures.imageJson
                        |> Result.map (\image -> ( image.imageUrl, image.filename ))
                    )
        , test "decodes a reply notification with comment data" <|
            \_ ->
                Expect.equal (Ok ( Domain.ReplyNotification, 20 ))
                    (decode Domain.notificationView Fixtures.notificationJson
                        |> Result.map
                            (\view ->
                                ( view.notification.kind
                                , case view.data of
                                    Domain.NotificationComment comment ->
                                        comment.comment.id

                                    _ ->
                                        -1
                                )
                            )
                    )
        , test "decodes a report page into a post report variant" <|
            \_ ->
                case decode (Domain.page Domain.reportView) Fixtures.reportJson of
                    Ok reportPage ->
                        case reportPage.items of
                            [ Domain.PostReportView report _ _ _ _ ] ->
                                Expect.equal (Ok "spam") (Ok report.reason)

                            _ ->
                                Expect.fail "expected one post report"

                    Err error ->
                        Expect.fail (Decode.errorToString error)
        , test "decodes a modlog page" <|
            \_ ->
                Expect.equal (Ok "mod_ban_from_community")
                    (decode (Domain.page Domain.modlogView) Fixtures.modlogJson
                        |> Result.map (\page -> page.items)
                        |> Result.map
                            (\items ->
                                case items of
                                    [ entry ] ->
                                        entry.modlog.kind

                                    _ ->
                                        "missing"
                            )
                    )
        , test "decodes known and unknown error codes" <|
            \_ ->
                Expect.equal
                    [ ( "not_logged_in", True )
                    , ( "conflict", True )
                    , ( "mystery", False )
                    ]
                    [ ( (Problem.decode 401 "{\"error\":\"not_logged_in\"}").code, Problem.isUnauthenticated (Problem.decode 401 "{\"error\":\"not_logged_in\"}") )
                    , ( (Problem.decode 409 "not-json").code, Problem.isConflict (Problem.decode 409 "not-json") )
                    , ( (Problem.decode 500 "{\"error\":\"mystery\"}").code, Problem.isForbidden (Problem.decode 500 "{\"error\":\"mystery\"}") )
                    ]
        , test "builds a comment tree from path segments" <|
            \_ ->
                let
                    nodes =
                        [ { id = 1, path = "0.1", childCount = 2 }
                        , { id = 2, path = "0.1.2", childCount = 0 }
                        , { id = 3, path = "0.1.3", childCount = 1 }
                        , { id = 4, path = "0.1.3.4", childCount = 0 }
                        , { id = 5, path = "0.99.5", childCount = 0 }
                        ]

                    tree =
                        CommentTree.build .id .path .childCount nodes
                in
                Expect.equal [ 1, 2, 3, 4, 5 ] (List.map .id (CommentTree.flatten tree))
        , test "keeps malformed paths at the root" <|
            \_ ->
                let
                    tree =
                        CommentTree.build .id
                            .path
                            .childCount
                            [ { id = 6, path = "not-a-path", childCount = 0 } ]
                in
                Expect.equal [ 6 ] (List.map .id (CommentTree.flatten tree))
        , test "advances and resets cursor pagination" <|
            \_ ->
                let
                    page =
                        { items = [ 1, 2 ], nextPage = Just "next", prevPage = Nothing }

                    cursor =
                        Pagination.advance Nothing page
                in
                Expect.equal ( Just "next", False, True )
                    ( Pagination.next cursor, Pagination.hasPrevious cursor, Pagination.atStart cursor )
        , test "derives ownership and moderation permissions" <|
            \_ ->
                let
                    user =
                        decode Domain.myUserInfo Fixtures.myUserJson |> Result.toMaybe

                    community =
                        decode Domain.communityView Fixtures.communityViewJson |> Result.toMaybe

                    post =
                        decode Domain.postView Fixtures.postViewJson |> Result.toMaybe
                in
                case ( user, community, post ) of
                    ( Just userValue, Just communityValue, Just postValue ) ->
                        Expect.equal
                            { canPost = True
                            , canEdit = True
                            , canModerate = False
                            , following = True
                            }
                            { canPost = Permissions.canPost (Just userValue) communityValue
                            , canEdit = Permissions.canEditPost (Just userValue) postValue
                            , canModerate = Permissions.canModeratePost (Just userValue) postValue
                            , following = Permissions.isFollowing communityValue
                            }

                    _ ->
                        Expect.fail "fixtures should decode"
        , test "does not grant authoring to another non-admin viewer" <|
            \_ ->
                let
                    otherUser =
                        String.replace "\"id\":1,\"name\":\"alice\"" "\"id\":2,\"name\":\"alice\"" Fixtures.myUserJson

                    user =
                        decode Domain.myUserInfo otherUser |> Result.toMaybe

                    post =
                        decode Domain.postView Fixtures.postViewJson |> Result.toMaybe
                in
                case ( user, post ) of
                    ( Just userValue, Just postValue ) ->
                        Expect.equal ( False, False )
                            ( Permissions.canEditPost (Just userValue) postValue
                            , Permissions.canDeletePost (Just userValue) postValue
                            )

                    _ ->
                        Expect.fail "fixtures should decode"
        , test "grants site administration to an admin viewer" <|
            \_ ->
                let
                    adminUser =
                        String.replace "\"admin\":false" "\"admin\":true" Fixtures.myUserJson

                    user =
                        decode Domain.myUserInfo adminUser |> Result.toMaybe

                    community =
                        decode Domain.communityView Fixtures.communityViewJson |> Result.toMaybe

                    post =
                        decode Domain.postView Fixtures.postViewJson |> Result.toMaybe
                in
                case ( user, community, post ) of
                    ( Just userValue, Just communityValue, Just postValue ) ->
                        Expect.equal ( True, True, True )
                            ( Permissions.isAdmin userValue
                            , Permissions.canModeratePost (Just userValue) postValue
                            , Permissions.canManageCommunity (Just userValue) communityValue
                            )

                    _ ->
                        Expect.fail "fixtures should decode"
        , test "decodes community tags and optional person actions" <|
            \_ ->
                let
                    tag =
                        decode Domain.communityTag
                            "{\"id\":5,\"name\":\"news\",\"display_name\":\"News\",\"summary\":null,\"community_id\":2,\"color\":\"color_01\",\"deleted\":false}"
                in
                Expect.equal (Ok ( 5, "News", "color_01" ))
                    (tag
                        |> Result.map
                            (\value ->
                                ( value.id, Maybe.withDefault value.name value.displayName, value.color )
                            )
                    )
        , test "keeps optional tags and person actions absent" <|
            \_ ->
                decode Domain.postView Fixtures.postViewJson
                    |> Result.map
                        (\view ->
                            ( List.isEmpty view.tags, view.personActions )
                        )
                    |> Expect.equal (Ok ( True, Nothing ))
        , test "decodes a tagged person content item" <|
            \_ ->
                let
                    itemJson =
                        "{\"type_\":\"post\"," ++ String.dropLeft 1 Fixtures.postViewJson
                in
                Expect.equal (Ok 10)
                    (decode Domain.personContentItem itemJson
                        |> Result.map
                            (\item ->
                                case item of
                                    Domain.PersonPost post ->
                                        post.post.id

                                    Domain.PersonComment comment ->
                                        comment.post.id
                            )
                    )
        , test "decodes a vote view" <|
            \_ ->
                let
                    voteJson =
                        "{\"creator\":" ++ Fixtures.personJson ++ ",\"creator_banned\":false,\"creator_banned_from_community\":false,\"is_upvote\":true}"
                in
                Expect.equal (Ok ( "alice", True ))
                    (decode Domain.voteView voteJson
                        |> Result.map (\vote -> ( vote.creator.name, vote.isUpvote ))
                    )
        ]
