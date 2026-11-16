## 1. File API client support

- [ ] 1.1 Add a multipart upload helper that posts one file under field `file` to `/api/v4/file`; verify the helper targets the v4 route and preserves same-origin authentication behavior.
- [ ] 1.2 Add a decoder for `public_id`, `url`, `filename`, `content_type`, and `size_bytes`; verify valid responses decode and missing or invalid required fields fail.
- [ ] 1.3 Add document upload error mappings and localized message keys for disabled uploads, rejected size or type, and unavailable storage; verify all three locale catalogs and generated Elm bindings contain the messages.

## 2. Editor upload flow

- [ ] 2.1 Route browser-reported image MIME types through the existing Pictrs request and other candidate files through the document endpoint; verify image uploads keep their current request and document requests use multipart field `file`.
- [ ] 2.2 Handle successful document uploads by appending an escaped Markdown download link and adding the returned filename and available metadata to editor state; verify existing source text remains intact.
- [ ] 2.3 Derive editor attachment entries from document links in the Markdown source and merge metadata for uploads in the current session; verify entries survive editor updates and are reconstructed when editing saved content.
- [ ] 2.4 Preserve the source and existing entries when an upload fails or returns malformed data; verify progress clears and a localized error is shown without inserting a link.

## 3. Post attachment display

- [ ] 3.1 Extract safe links matching the v4 file download route from parsed Markdown; verify images, malformed routes, unsafe URLs, and ordinary links are excluded.
- [ ] 3.2 Render extracted document links in a separate attachment section on post detail pages while retaining inline body links; verify links have meaningful localized section labels and accessible names.

## 4. Localization and verification

- [ ] 4.1 Add localized labels and accessible status messages for editor attachments and post detail attachments in all supported locales; verify `npm run i18n:check` passes.
- [ ] 4.2 Add focused Elm tests for document response decoding, editor link insertion and failure preservation, and Markdown attachment extraction; verify the focused tests pass.
- [ ] 4.3 Verify the integrated change with `npm run compile`, `npm test`, `npm run format:check`, `npm run i18n:check`, and the relevant browser tests; record any backend configuration needed for a live upload acceptance check.
