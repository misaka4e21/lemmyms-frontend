## Why

The editor already offers a file picker, but sends every selected file to the image endpoint and inserts it as a Markdown image. The backend now provides a separate document upload API, so readers need a frontend flow that uploads documents and links to them correctly.

## What Changes

- Keep images on the existing Pictrs endpoint and upload documents through `POST /api/v4/file`.
- Insert each uploaded document as a Markdown download link and show it in the editor's attachment list.
- Show document links from post Markdown in a separate attachment list on post detail pages.
- Localize upload progress, success, and error feedback in the supported catalogs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `lemmy-api-integration`: Specify document upload request and response handling alongside the existing image upload contract.
- `forum-application`: Distinguish document links uploaded through the file API from images uploaded through Pictrs in Markdown authoring.

## Impact

The editor API and state in `src/Feature/Editor`, upload helpers and response decoders in `src/Lemmy`, localization catalogs, and the corresponding generated translation assets. The change consumes the existing backend `/api/v4/file` API and does not require a backend API change.
