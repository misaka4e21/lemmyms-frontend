## MODIFIED Requirements

### Requirement: Shared Markdown authoring surface
The application SHALL provide a source-first Markdown editor for post creation, comment replies, post and comment editing, and profile biography editing. The editor SHALL preserve the stored Markdown source, load existing values from the v4 post, comment, or person response rather than reconstructing them from rendered output, and submit only the user-edited source. The editor SHALL provide visible controls for bold, italic, link, inline code, quote, bullet list, and numbered list. Formatting actions SHALL apply to the current selection, preserve focus and the surrounding text, and work with keyboard and pointer input. The editor SHALL NOT use contenteditable rendering or inject editor source as trusted HTML.

#### Scenario: Topic and reply authoring stay consistent
- **WHEN** an authenticated reader composes a post or comment
- **THEN** the same Markdown authoring surface is presented, the submitted body remains Markdown source, and no rendered HTML is sent in place of the source

#### Scenario: Profile biography uses Markdown authoring
- **WHEN** an authenticated reader opens profile settings
- **THEN** the biography field uses the shared Markdown authoring surface and saves the edited Markdown source through the account settings endpoint

#### Scenario: Formatting applies to the selection
- **WHEN** a reader selects text and activates a formatting control
- **THEN** only the selected range is wrapped or prefixed, the remaining text is unchanged, and focus returns to the editor

#### Scenario: Existing source is not reconstructed
- **WHEN** a reader edits an existing post, comment, or biography
- **THEN** the editor starts from the exact Markdown source returned by the API and does not serialize rendered output back into the field

#### Scenario: Legacy source remains legacy
- **WHEN** a reader edits stored content that originated outside Lemmy Markdown
- **THEN** the editor preserves the exact source text and does not invent a separate legacy content format

### Requirement: Mention candidate lookup
While an authenticated reader is editing a post or biography, the application SHALL offer mention candidates after an `@` token reaches two and at most sixty-four Unicode code points. The application SHALL request at most eight person candidates from the v4 search endpoint using the active token and a users-only search type, SHALL debounce repeated input, and SHALL ignore responses that no longer match the active token. It SHALL present loading, empty, and unavailable states without blocking text entry or submission. The candidate response SHALL be treated as display data only; the application SHALL NOT invent handles, perform WebFinger or Actor discovery, or imply that a candidate is a current community member.

#### Scenario: Query after two characters
- **WHEN** a reader types `@al` in an authoring field
- **THEN** the application requests person candidates for `al` and presents matching local and known remote accounts

#### Scenario: One character does not query
- **WHEN** a reader has typed only `@a`
- **THEN** no candidate request is issued and the editor remains usable

#### Scenario: Stale response is ignored
- **WHEN** a candidate response arrives after the active mention token has changed
- **THEN** the stale items are not displayed and the current token state remains unchanged

#### Scenario: Candidate lookup is unavailable
- **WHEN** the candidate request fails or returns an error
- **THEN** the editor reports a localized non-blocking state, preserves the source text, and still permits submission

## ADDED Requirements

### Requirement: Sanitized Markdown rendering
The application SHALL render post bodies, comments, biographies, community sidebars, and site text from their Markdown source. Rendering SHALL allow only the supported element and attribute allowlist, SHALL reject unsafe URL schemes, SHALL apply no-referrer behavior to remote images, and SHALL NOT inject unfiltered HTML. When rendering fails, the interface SHALL present the source as text rather than an empty or partially trusted tree.

#### Scenario: Render a Markdown post
- **WHEN** a post body contains headings, links, code, lists, and images
- **THEN** the interface renders the supported elements with the allowlist applied and no raw script or event-handler attribute survives

#### Scenario: Unsafe link is present
- **WHEN** Markdown contains a link or image URL with an unsupported scheme
- **THEN** the unsafe target is omitted while the surrounding text remains readable

#### Scenario: Rendering fails
- **WHEN** the Markdown parser returns an error
- **THEN** the interface displays the original source text without claiming it is rendered content
