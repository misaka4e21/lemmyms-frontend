## MODIFIED Requirements

### Requirement: Markdown content and media
The application SHALL treat post `body`, comment `content`, person `bio`, community `sidebar`, and site text as Markdown source. It SHALL render that source through the shared sanitized Markdown renderer and SHALL NOT expect a `body_html` field. Images SHALL be uploaded through the v4 Pictrs image endpoint, and the returned `image_url` and `filename` SHALL be retained. Documents SHALL be uploaded through the v4 file endpoint and inserted into the Markdown source as links using the returned filename and URL. The editor SHALL show uploaded documents in a separate attachment list. Post detail pages SHALL identify links to v4 file download routes in the Markdown source and show those files in a separate attachment list while preserving the inline Markdown links. Remote images SHALL use no-referrer behavior. Editor source SHALL never be injected as trusted HTML.

#### Scenario: Upload a document while composing
- **WHEN** an authenticated reader uploads a document in the post or comment editor
- **THEN** the editor adds a Markdown download link to the source and lists the document separately by its filename

#### Scenario: View documents on a post
- **WHEN** a post body contains Markdown links to v4 file download routes
- **THEN** the post detail page renders the body links and a separate attachment list with downloadable links to those files

#### Scenario: Edit a post with document links
- **WHEN** a reader edits a post whose Markdown source contains v4 file download links
- **THEN** the source remains unchanged and the editor attachment list includes the linked documents

#### Scenario: Upload fails
- **WHEN** an image or document upload is rejected or unavailable
- **THEN** the editor retains the unsent text and existing attachment entries, identifies the failure, and does not add a fabricated URL

#### Scenario: Markdown contains unsupported HTML
- **WHEN** a post body contains script, event-handler attributes, or an unsafe URL scheme
- **THEN** the renderer omits the unsafe content while preserving the surrounding readable text
