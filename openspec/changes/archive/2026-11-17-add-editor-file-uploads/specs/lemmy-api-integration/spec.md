## MODIFIED Requirements

### Requirement: Pictrs media boundary
The application SHALL upload images through the v4 Pictrs image endpoint and SHALL use the returned `image_url` and `filename` for display and cleanup. It SHALL reject an image upload response that lacks a usable image URL and SHALL retain the editor text and existing attachments when an upload fails. The application SHALL upload documents through `POST /api/v4/file` as multipart field `file`, decode `public_id`, `url`, `filename`, `content_type`, and `size_bytes`, and retain the returned URL and filename. It SHALL treat upload errors or malformed responses as localized failures and preserve the editor source and previously uploaded attachment entries.

#### Scenario: Upload a post image
- **WHEN** an authenticated reader uploads an image while composing
- **THEN** the application inserts the returned `image_url` into the Markdown source and keeps the returned `filename` available for deletion

#### Scenario: Upload a document
- **WHEN** an authenticated reader uploads a document while composing a post or comment
- **THEN** the application sends the file as multipart field `file`, inserts a Markdown download link using the returned filename and URL, and adds the document to the editor attachment list

#### Scenario: Document upload is rejected
- **WHEN** the file API rejects a document because uploads are disabled, its size or detected type violates site policy, or storage is unavailable
- **THEN** the application reports a localized error, clears the upload-in-progress state, and preserves the Markdown source and existing attachment entries

#### Scenario: Document upload response is malformed
- **WHEN** the file API returns success without a usable URL or filename
- **THEN** the editor reports a localized failure and does not add a link or attachment entry

#### Scenario: Upload response is malformed
- **WHEN** the image endpoint returns success without a usable image URL
- **THEN** the editor reports a localized failure and does not insert a fabricated attachment
