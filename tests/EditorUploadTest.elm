module EditorUploadTest exposing (suite)

import Expect
import Feature.Authoring.State as Authoring
import Feature.Editor.State as Editor
import Feature.Editor.Update as Update
import Remote exposing (Remote(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "editor document uploads"
        [ test "appends a download link while preserving existing source" <|
            \_ ->
                let
                    mode =
                        Editor.CreateTopic "2"

                    initial =
                        editorModel mode "existing text"

                    response =
                        { status = 200
                        , body =
                            "{\"public_id\":\"550e8400-e29b-41d4-a716-446655440000\",\"url\":\"https://forum.test/api/v4/file/550e8400-e29b-41d4-a716-446655440000/report.pdf\",\"filename\":\"report.pdf\",\"content_type\":\"application/pdf\",\"size_bytes\":1024}"
                        }

                    ( updated, _, _ ) =
                        Update.update "" (Update.Uploaded mode Update.DocumentUploadKind response) initial
                in
                case updated.editor of
                    Just editor ->
                        Expect.equal
                            ( "existing text\n\n[report.pdf](https://forum.test/api/v4/file/550e8400-e29b-41d4-a716-446655440000/report.pdf)\n"
                            , 1
                            , False
                            )
                            ( Authoring.value editor.authoring, List.length editor.attachments, editor.uploading )

                    Nothing ->
                        Expect.fail "editor state should remain available after upload"
        , test "preserves source and attachments when the upload response is malformed" <|
            \_ ->
                let
                    mode =
                        Editor.CreateTopic "2"

                    initial =
                        editorModel mode "existing text\n\n[existing.pdf](https://forum.test/api/v4/file/650e8400-e29b-41d4-a716-446655440000/existing.pdf)"

                    response =
                        { status = 200, body = "{}" }

                    ( updated, _, _ ) =
                        Update.update "" (Update.Uploaded mode Update.DocumentUploadKind response) initial
                in
                case updated.editor of
                    Just editor ->
                        Expect.equal
                            { body = "existing text\n\n[existing.pdf](https://forum.test/api/v4/file/650e8400-e29b-41d4-a716-446655440000/existing.pdf)", attachmentCount = 1, uploading = False, hasProblem = True }
                            { body = Authoring.value editor.authoring
                            , attachmentCount = List.length editor.attachments
                            , uploading = editor.uploading
                            , hasProblem = editor.problem /= Nothing
                            }

                    Nothing ->
                        Expect.fail "editor state should remain available after upload failure"
        ]


editorModel : Editor.EditorMode -> String -> Editor.Model
editorModel mode source =
    let
        editor =
            Editor.emptyEditor mode
    in
    { editor
        | authoring = Authoring.init "editor-body" source
        , attachments = Editor.sourceAttachments { title = "", body = source, version = "0" }
        , uploading = True
    }
        |> Just
        |> (\current -> { editor = current, source = NotAsked })
