## Purpose

Define the browser-facing contract between the Elm application and a Lemmy `1.0.0-beta.3` v4 API, including same-origin transport, HttpOnly session cookies, DTO decoding, cursor pagination, error outcomes, and media boundaries.

## ADDED Requirements

### Requirement: Same-origin v4 API boundary
The application SHALL send every Lemmy request to the same-origin `/api/v4` prefix and SHALL NOT call the retired Commune `/api/v1` endpoints. Requests SHALL include browser credentials so an HttpOnly session cookie is sent automatically. The application SHALL NOT read the JWT from JavaScript, browser storage, or a response body.

#### Scenario: Authenticated request after reload
- **WHEN** an authenticated reader reloads the application and opens a protected route
- **THEN** the browser sends the existing HttpOnly session cookie with the v4 request and the application restores the account without reading a token in JavaScript

#### Scenario: No legacy fallback
- **WHEN** a v4 request fails with a missing-resource or unsupported-operation response
- **THEN** the application does not retry the same operation against `/api/v1` or another backend prefix

### Requirement: HttpOnly session lifecycle
Login SHALL succeed only when the backend establishes an HttpOnly `jwt` cookie for the current origin, and the application SHALL treat the returned JSON JWT as opaque. Logout SHALL invalidate the server session and remove the cookie. A 401 response SHALL move the application to an anonymous state, clear protected visible data, and offer reauthentication without retrying the failed mutation.

#### Scenario: Successful login
- **WHEN** a reader submits valid credentials
- **THEN** the backend sets an HttpOnly `jwt` cookie, the application discards the JSON token, and subsequent requests are authenticated by the cookie

#### Scenario: Session expires
- **WHEN** a protected request returns 401
- **THEN** the application clears protected state, keeps unsent form text, and prompts the reader to sign in again

#### Scenario: Logout removes the session
- **WHEN** an authenticated reader logs out
- **THEN** the backend invalidates the login token and the browser no longer sends a usable `jwt` cookie

### Requirement: Lemmy v4 DTO decoding
The application SHALL decode the v4 response DTOs used by the migrated features, including site, account, post, comment, community, person, notification, report, modlog, and media responses. Optional fields SHALL be treated as absent rather than invented. Identifier values SHALL remain exact integers, and actor or federation identifiers SHALL remain opaque strings.

#### Scenario: Optional display fields are absent
- **WHEN** a post, comment, community, or person omits an optional display field
- **THEN** the interface renders the available fallback without rejecting the entire response

#### Scenario: Unknown optional field is added
- **WHEN** the backend adds a field that the application does not use
- **THEN** decoding succeeds and the extra field is ignored

### Requirement: Cursor pagination
The application SHALL use `page_cursor`, `next_page`, and `prev_page` for migrated collections. It SHALL NOT derive offset pagination, total counts, or page numbers from a cursor response. Moving to the next or previous page SHALL reuse the cursor returned by the same endpoint, and changing sort or filter SHALL start a new cursor sequence.

#### Scenario: Load the next page
- **WHEN** a reader activates the next-page control on a post or comment list
- **THEN** the request sends the previous response's `next_page` cursor and replaces the list with the returned page

#### Scenario: Change sort resets pagination
- **WHEN** a reader changes the post or comment sort
- **THEN** the application requests the first page without a cursor from the previous sort

#### Scenario: Cursor is absent
- **WHEN** the current response has no `next_page`
- **THEN** the interface disables further navigation and does not fabricate a final page number

### Requirement: Backend error mapping
The application SHALL map v4 error responses containing `error` and optional `message` to localized outcomes. It SHALL distinguish unauthenticated, forbidden, not-found, conflict, rate-limited, validation, and unavailable states. Backend prose SHALL NOT be presented as interface copy, and a mutation SHALL NOT be automatically retried.

#### Scenario: Rate-limited mutation
- **WHEN** a write returns the v4 rate-limit error
- **THEN** the application reports a localized retry-later outcome and preserves the reader's input

#### Scenario: Unknown error code
- **WHEN** the response contains an error code not present in the local catalog
- **THEN** the application presents a generic localized failure and retains the status for diagnostics without exposing raw server prose

### Requirement: Pictrs media boundary
The application SHALL upload images through the v4 Pictrs image endpoint and SHALL use the returned `image_url` and `filename` for display and cleanup. It SHALL reject an upload response that lacks a usable image URL and SHALL retain the editor text and existing attachments when an upload fails.

#### Scenario: Upload a post image
- **WHEN** an authenticated reader uploads an image while composing
- **THEN** the application inserts the returned `image_url` into the Markdown source and keeps the returned `filename` available for deletion

#### Scenario: Upload response is malformed
- **WHEN** the image endpoint returns success without a usable image URL
- **THEN** the editor reports a localized failure and does not insert a fabricated attachment
