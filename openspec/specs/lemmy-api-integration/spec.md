# lemmy-api-integration Specification

## Purpose

Define the browser-facing contract between the Elm application and a Lemmy `1.0.0-beta.3` v4 API, including same-origin transport, HttpOnly session cookies, DTO decoding, cursor pagination, error outcomes, and media boundaries.

## Requirements

### Requirement: Same-origin v4 API boundary
The application SHALL use the same-origin `/api/v4` prefix for all migrated reads and writes and SHALL NOT call the retired Commune `/api/v1` endpoints. Session establishment is the sole temporary exception: login SHALL call `/api/v3/user/login` to receive the HttpOnly `jwt` cookie until the v4 login route sets that cookie. The login response body SHALL NOT be used as application data; the application SHALL immediately verify the session through `/api/v4/account`. Requests SHALL include browser credentials so the HttpOnly cookie is sent automatically. The application SHALL NOT read the JWT from JavaScript, browser storage, or a response body.

#### Scenario: Authenticated request after reload
- **WHEN** an authenticated reader reloads the application and opens a protected route
- **THEN** the browser sends the existing HttpOnly session cookie with the v4 request and the application restores the account without reading a token in JavaScript

#### Scenario: No legacy fallback
- **WHEN** a v4 read or write fails with a missing-resource or unsupported-operation response
- **THEN** the application does not retry that operation against `/api/v1`, `/api/v3`, or another backend prefix

#### Scenario: Temporary v3 login bridge
- **WHEN** a reader submits valid credentials while the v4 login route still lacks `Set-Cookie`
- **THEN** the application calls `/api/v3/user/login` only to establish the HttpOnly cookie, then loads the account from `/api/v4/account` and does not use the v3 response body as session data

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
### Requirement: Extended v4 DTO coverage
The application SHALL decode community tags on community and post views, person actions on post and comment views, vote views from post and comment like lists, and person content as a tagged union of post and comment views. Optional fields SHALL remain absent rather than invented.

#### Scenario: Tagged community view
- **WHEN** a community or post response includes a tag list
- **THEN** decoding succeeds and the tags remain available to the view

#### Scenario: Person content item
- **WHEN** a person content response returns a post or comment item
- **THEN** the item is decoded as the matching view and unknown extra fields are ignored

### Requirement: Extended v4 action requests
The application SHALL use the existing v4 routes for post and comment removal, locking, community featuring, comment distinguishing, post read state, person and community blocks, post and comment like lists, community tag creation and deletion, community icon and banner upload, and community notification mode changes. Requests SHALL carry the identifiers and booleans required by those routes and SHALL NOT retry a failed mutation automatically.

#### Scenario: Post moderation request
- **WHEN** a moderator removes or locks a post
- **THEN** the request targets the post moderation route with the post identifier and the requested state

#### Scenario: Community image request
- **WHEN** a manager uploads a community icon or banner
- **THEN** the multipart request targets the matching community image route with the community identifier in the query

### Requirement: Extended v4 search and person content queries
Search SHALL send `type_` values for all, comments, posts, communities, and users, and SHALL use `post_url_only` for URL search. Person content SHALL send the username or person identifier with an optional content type, and both queries SHALL preserve the same `page_cursor` contract used by other v4 lists.

#### Scenario: Search type query
- **WHEN** a reader searches for comments or users
- **THEN** the request includes the matching `type_` value and the current cursor when one exists

#### Scenario: Person content query
- **WHEN** a profile tab requests comments
- **THEN** the request includes the username and `type_=comments` and replaces the list with the returned page
### Requirement: Complete account settings transport
The application SHALL decode the account settings fields returned by `GET /account` and SHALL send supported optional fields to `PUT /account/settings/save`. Clearing an optional text field SHALL be represented explicitly. The application SHALL use the avatar and banner upload and delete endpoints for account images and SHALL NOT place image bytes or credentials in browser storage.

#### Scenario: Settings save request
- **WHEN** a reader saves the complete settings form
- **THEN** the request contains the selected booleans, strings, numeric limits, discussion languages, and blocking keywords

#### Scenario: Banner upload
- **WHEN** a reader uploads a profile banner
- **THEN** the multipart request targets the account banner endpoint and the refreshed account uses the returned URL

### Requirement: Security and session requests
The application SHALL use `POST /account/auth/totp/generate`, `POST /account/auth/totp/edit`, `GET /account/login/list`, `DELETE /account`, and `PUT /account/auth/change_password` for the corresponding security workflows. A deletion request SHALL include the password and content-deletion choice. A successful deletion SHALL end the local session.

#### Scenario: TOTP edit request
- **WHEN** a reader enables or disables TOTP
- **THEN** the request includes the token and the requested enabled state

#### Scenario: Account deletion request
- **WHEN** a reader confirms deletion
- **THEN** the request includes the password and content-deletion boolean and a successful response clears the session

### Requirement: Backup invitation and captcha requests
The application SHALL use `GET /account/settings/export`, `POST /account/settings/import`, `GET /account/data/export`, `GET /account/invite/list`, `POST /account/invite`, `DELETE /account/invite`, and `GET /account/auth/get_captcha`. Settings import SHALL submit the selected JSON without reconstructing it. Invitation requests SHALL carry optional maximum uses and expiry. Registration SHALL carry the application answer, captcha UUID and answer, and invitation token when present.

#### Scenario: Settings import body
- **WHEN** a reader imports a backup
- **THEN** the request body is the selected JSON document and the endpoint response updates the settings state

#### Scenario: Invitation creation request
- **WHEN** a reader creates an invitation
- **THEN** the request includes the optional maximum uses and expiry

#### Scenario: Registration request
- **WHEN** a reader submits a guarded registration form
- **THEN** the request includes the answer, captcha fields, or invitation token required by the site mode
