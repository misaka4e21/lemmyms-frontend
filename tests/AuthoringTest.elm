module AuthoringTest exposing (suite)

import Expect
import Feature.Authoring.State as Authoring
import Feature.Authoring.Update as Update
import Lemmy.Domain as Domain
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Markdown authoring"
        [ test "detects the active mention token" <|
            \_ ->
                Expect.equal (Just ( 6, "al" ))
                    (Authoring.detectToken "hello @al" 9
                        |> Maybe.map (\token -> ( token.start, token.query ))
                    )
        , test "does not detect an email or a token longer than the limit" <|
            \_ ->
                Expect.equal [ Nothing, Nothing ]
                    [ Authoring.detectToken "mail me at a@b.test" 18
                    , Authoring.detectToken ("@" ++ String.repeat 65 "a") 66
                    ]
        , test "wraps the current selection" <|
            \_ ->
                let
                    model =
                        Authoring.init "editor-body" "hello world"
                            |> Authoring.setSelection 6 11
                in
                Expect.equal (Just ( "**world**", 6, 15 ))
                    (Authoring.format Authoring.Bold model
                        |> Maybe.map (\replacement -> ( replacement.text, replacement.start, replacement.caret ))
                    )
        , test "prefixes each selected line" <|
            \_ ->
                let
                    model =
                        Authoring.init "editor-body" "a\nb"
                            |> Authoring.setSelection 0 3
                in
                Expect.equal (Just "- a\n- b")
                    (Authoring.format Authoring.BulletList model |> Maybe.map .text)
        , test "inserts the complete candidate handle" <|
            \_ ->
                let
                    model =
                        Authoring.init "editor-body" "hello @al"
                            |> Authoring.setSelection 9 9

                    candidate =
                        { person =
                            { id = 1
                            , name = "alice"
                            , displayName = Just "Alice"
                            , avatar = Nothing
                            , banner = Nothing
                            , bio = Nothing
                            , local = True
                            , deleted = False
                            , botAccount = False
                            , apId = "https://forum.test/users/alice"
                            , instanceId = 1
                            , postCount = 0
                            , commentCount = 0
                            , publishedAt = "2026-11-10T00:00:00Z"
                            , updatedAt = Nothing
                            }
                        , isAdmin = False
                        , personActions = Nothing
                        , banned = False
                        , banExpiresAt = Nothing
                        }
                in
                Expect.equal (Just ( "@alice@forum.test ", 6, 24 ))
                    (Authoring.candidateReplacement candidate model
                        |> Maybe.map (\replacement -> ( replacement.text, replacement.start, replacement.caret ))
                    )
        , test "ignores a stale candidate response" <|
            \_ ->
                let
                    model =
                        Authoring.init "editor-body" "hello @bo"
                            |> Authoring.setSelection 9 9

                    pending =
                        { model
                            | mention = Just { start = 6, end = 9, query = "bo" }
                            , status = Authoring.Pending
                            , generation = 5
                        }

                    ( next, _, _ ) =
                        Update.update
                            (Update.CandidatesLoaded 4 { status = 200, body = "{\"items\":[]}" })
                            pending
                in
                Expect.equal Authoring.Pending next.status
        ]
