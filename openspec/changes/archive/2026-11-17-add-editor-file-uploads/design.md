## Context

The shared editor handles topic creation, replies, and edits. Its file picker currently sends every file to the image endpoint, then appends Markdown image syntax. The backend document API accepts a multipart `file` field and returns a site URL, filename, detected MIME type, size, and public ID. Posts and comments store Markdown source, and post details already render that source through the shared safe Markdown renderer.

## Goals / Non-Goals

**Goals:**

- Keep image uploads on Pictrs and send documents to the file API.
- Add a Markdown download link and an attachment entry after a successful document upload.
- Reconstruct attachment entries from Markdown when opening an existing editor or displaying a post.
- Preserve drafts and prior attachment entries on upload failure.

**Non-Goals:**

- Add a backend attachment field or ActivityPub attachment federation.
- Add a file manager, site policy controls, or server-side orphan cleanup.
- Add document upload controls to profile biographies or site settings.

## Decisions

### Keep upload types on their existing API boundaries

Use the existing Pictrs request for images. Send documents to `POST /api/v4/file` as multipart field `file`, and decode the backend response fields. The backend detects actual content type and applies the site's size, MIME, and enabled policies, so the frontend must report those errors without relying on the filename extension. The file API rejects image and video content.

Alternative considered: send every file to the document API and let it reject images. Keeping image uploads on Pictrs preserves existing image rendering and cleanup behavior.

### Store document references in Markdown and derive the visible lists

After upload succeeds, append `[filename](url)` to the current Markdown source, separated from existing text by a blank line. Escape Markdown syntax in the visible filename and use the returned encoded URL. Keep the returned metadata in editor state for the current editing session. Build the editor list from document links in the source, merging response metadata for files uploaded in that session. On later edits, derive the filename from the Markdown link and leave unknown metadata absent.

On post detail pages, walk parsed Markdown links and identify destinations whose path matches `/api/v4/file/{public_id}/{filename}`. Render matching links in a separate attachment section with the Markdown label as the accessible name. Keep rendering the original body, including its inline download links. Do not treat images, arbitrary links, or malformed file routes as document attachments. Link rendering continues through the existing safe URL checks.

Alternative considered: store an independent attachment collection in the frontend or infer a second backend contract. The backend only persists the file reference and the Markdown body contains the durable URL, so deriving the list from Markdown keeps the displayed list consistent with saved content.

### Keep upload interactions compatible with the shared editor

Use the current native file picker and upload-in-progress state. One selected file is uploaded per request; readers can repeat the action to add more files. Append the generated link to the source as the current image flow does. A failed or malformed response clears progress, reports a localized error, and leaves the source and existing attachment entries intact.

Add message keys to the English, Simplified Chinese, and Traditional Chinese Fluent catalogs, then regenerate the typed Elm bindings and locale assets using the established project scripts.

## Risks / Trade-offs

- [A site may disable document uploads or reject a file by size or detected MIME type] → Display the mapped localized API error and retain the user's draft.
- [Markdown links can be edited manually or point to a removed file] → Derive the list from the current source and treat the backend download response as authoritative.
- [A document link is shown inline and in the post attachment section] → This duplication is the requested presentation; both entries use the same backend URL.
- [Removing a link from Markdown does not delete its backend file reference] → Keep file deletion and orphan cleanup outside this frontend change.

## Migration Plan

No data migration is needed. Existing posts remain readable. During editing and display, the frontend can derive attachment entries for Markdown links that already use the backend file route. Rollback consists of restoring the previous frontend assets; uploaded objects and stored Markdown remain on the backend.
