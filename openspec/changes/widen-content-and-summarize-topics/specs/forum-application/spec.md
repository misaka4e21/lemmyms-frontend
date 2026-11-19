# Spec Delta

## MODIFIED Requirements

### Requirement: Posts comments and editing
The application SHALL display Lemmy posts and their comments, allow authorized creation, reply, editing, deletion, voting, saving, reading, hiding, and reporting. Posts and comments SHALL be decoded as distinct DTOs. The application SHALL derive authoring authority from the authenticated person's ID, the post or comment `creator_id`, `can_mod`, and the viewer's community moderation or site-admin roles. It SHALL NOT rely on the removed Commune `permissions` object, and it SHALL NOT invent an expected-version field because v4 does not provide one. A failed edit SHALL preserve the draft and reload the current source for comparison without automatic retry. Topic post lists SHALL display an available post summary, or a bounded excerpt from the post body when no summary is available. Discussion pages and reply lists SHALL continue to display full post and reply content.

#### Scenario: Topic list uses available summary
- **WHEN** a topic list displays a post with a non-empty summary
- **THEN** the card shows the summary instead of the full post body

#### Scenario: Topic list falls back to bounded body excerpt
- **WHEN** a topic list displays a post with no summary and a body longer than the excerpt limit
- **THEN** the card displays a readable excerpt that ends at the configured limit and indicates omitted content

#### Scenario: Discussion retains full post body
- **WHEN** a reader opens a post discussion
- **THEN** the post body is displayed in full

#### Scenario: Reply list retains full reply content
- **WHEN** a reader views replies in a post discussion or another reply list
- **THEN** each reply's full content is displayed

#### Scenario: Edit a post
- **WHEN** an authorized author opens the post editor
- **THEN** the editor starts from the post's Markdown title and body returned by v4 and submits those fields without reconstructing them from rendered output

#### Scenario: Permission is revoked
- **WHEN** a formerly permitted mutation returns 403 or a protected read returns 404
- **THEN** the interface explains the unavailable action, refreshes applicable permissions, and does not report success

#### Scenario: Concurrent edit
- **WHEN** two tabs save the same post and the later save overwrites the earlier one
- **THEN** the application does not claim optimistic-lock protection that v4 does not provide; it preserves the draft on failure and reloads the current content after success or conflict

### Requirement: Markdown content and media
The application SHALL treat post `body`, comment `content`, person `bio`, community `sidebar`, and site text as Markdown source. It SHALL render that source through the shared sanitized Markdown renderer and SHALL NOT expect a `body_html` field. Images SHALL be uploaded through the v4 Pictrs image endpoint, and the returned `image_url` and `filename` SHALL be retained. Documents SHALL be uploaded through the v4 file endpoint and inserted into the Markdown source as links using the returned filename and URL. The editor SHALL show uploaded documents in a separate attachment list. Post detail pages SHALL identify links to v4 file download routes in the Markdown source and show those files in a separate attachment list while preserving the inline Markdown links. Remote images SHALL use no-referrer behavior. Editor source SHALL never be injected as trusted HTML. Markdown content SHALL remain within the available content width; long unbroken text SHALL wrap, and intrinsically wide content SHALL fit or scroll within its container without widening the page.

#### Scenario: Long text stays within the content area
- **WHEN** rendered Markdown contains a long URL or other unbroken text
- **THEN** it wraps or clips within the content area without causing page-level horizontal overflow

#### Scenario: Wide code and media stay contained
- **WHEN** rendered Markdown contains a wide code block, table, or image
- **THEN** the content remains bounded to the content area, with local scrolling where needed

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

### Requirement: Main content width follows available layout space
The main content area SHALL grow with the available width to the right of the navigation drawer, while retaining readable horizontal margins and a sensible maximum width. It SHALL adapt to the viewport and drawer state without horizontal page overflow.

#### Scenario: Main content uses available desktop width
- **WHEN** a reader views the application on a wide viewport with the permanent drawer open
- **THEN** the main content area expands to use the available right-side space while keeping its configured side margins and maximum width

#### Scenario: Main content adapts to narrow viewport
- **WHEN** a reader views the application on a narrow viewport or with a modal drawer
- **THEN** the main content fits the viewport with narrow side margins and no horizontal page overflow
