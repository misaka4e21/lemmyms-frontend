## REMOVED Requirements

### Requirement: Navigable application and discovery
**Reason**: The route shapes, listing types, sort controls, and cursor pagination are replaced by Lemmy canonical URLs and v4 listing contracts.
**Migration**: Use `Lemmy canonical navigation and discovery`.

### Requirement: Session and verified registration
**Reason**: Commune session cookies and CSRF are replaced by an HttpOnly Lemmy JWT cookie and v4 registration modes.
**Migration**: Use `Lemmy session and verified registration`.

### Requirement: Discussions and editing
**Reason**: Lemmy separates posts from comments and has no source endpoint, expected-version field, or Commune permission object.
**Migration**: Use `Posts comments and editing`.

### Requirement: Attachments and safe rich content
**Reason**: Commune media references and server-rendered HTML are replaced by Pictrs image uploads and client-side Markdown rendering.
**Migration**: Use `Markdown content and media`.

### Requirement: Lemmy profiles search and notifications
**Reason**: Lemmy exposes profiles, search, and notifications through different DTOs, search parameters, and read endpoints.
**Migration**: Use `Profiles search and notifications`.

### Requirement: Lemmy community creation and management
**Reason**: Lemmy uses visibility, posting restrictions, moderators, pending follows, and separate report/modlog contracts instead of Commune policies, submissions, removals, and backfill.
**Migration**: Use `Community creation and management` and `Removed Commune-only management operations`.

### Requirement: Post voting and content state
**Reason**: Lemmy votes use `is_upvote: true|false|null`, and saved/read/hidden state comes from action records.
**Migration**: Use `Voting and content state`.

### Requirement: Recursive reply presentation
**Reason**: Lemmy returns comments with a `path` ltree and `child_count`, not nested `children` and `depth` fields.
**Migration**: Use `Comment tree presentation`.

### Requirement: Lemmy community follow lifecycle
**Reason**: Lemmy exposes `follow_state` values and community actions rather than Commune's follow policy fields.
**Migration**: Use `Community follow lifecycle`.

### Requirement: Account content collections
**Reason**: Lemmy exposes saved, read, hidden, and liked collections through v4 account endpoints with cursor pagination.
**Migration**: Use `Account collections and personal blocks`.

### Requirement: Personal blocking
**Reason**: Lemmy blocks persons and communities by integer ID and instance blocks by instance records, not Actor URI targets.
**Migration**: Use `Account collections and personal blocks`.

### Requirement: Lemmy reporting and moderation feedback
**Reason**: Lemmy has separate post, comment, community, and private-message report contracts; it has no person-report endpoint.
**Migration**: Use `Reporting and moderation feedback`.

### Requirement: Moderation history and bans
**Reason**: Lemmy uses `ModlogView` and person-ID community bans rather than Commune moderation rows and Actor URI bans.
**Migration**: Use `Moderation history and community bans`.

### Requirement: Lemmy notification target routing
**Reason**: Lemmy notifications use a typed `NotificationView` with comment, post, private-message, and modlog references.
**Migration**: Use `Notification target routing`.

### Requirement: Lemmy password reset and change
**Reason**: Lemmy uses `/account/auth/password_reset`, `/account/auth/password_change`, and `/account/auth/change_password` with its own field names.
**Migration**: Use `Password reset and change`.

### Requirement: Lemmy contract fidelity and secure transport
**Reason**: The v4 contract uses an HttpOnly cookie, no CSRF header, `{error}` responses, and cursor pagination.
**Migration**: Use `Contract fidelity and secure transport`.

## ADDED Requirements

### Requirement: Lemmy canonical navigation and discovery
The application SHALL provide bookmarkable Lemmy routes for the migrated features: `/`, `/communities`, `/c/:name`, `/post/:post_id/:comment_id?`, `/comment/:comment_id`, `/create_post`, `/create_community`, `/c/:name/settings`, `/u/:username`, `/search`, `/notifications`, `/settings`, `/admin`, `/reports`, and `/modlog/:communityId?`. Browser back, forward, and direct loading SHALL work. Post and comment lists SHALL use v4 `page_cursor` navigation plus the supported `ListingType` and sort values. The application SHALL NOT invent totals, page numbers, or unsupported sorts.

#### Scenario: Direct post navigation
- **WHEN** a reader loads `/post/:post_id` directly and then returns to the previous list
- **THEN** the application loads the authorized post and comments and restores the list route and cursor context

#### Scenario: Empty or unavailable collection
- **WHEN** a listing is empty or its request fails
- **THEN** the interface distinguishes empty, loading, and error states and offers an appropriate retry without fabricated content

#### Scenario: Protected route without a session
- **WHEN** an anonymous reader opens an account, notification, settings, or management route
- **THEN** the application explains that authentication is required and does not issue protected reads

### Requirement: Lemmy session and verified registration
The application SHALL support username-or-email login, session restoration through the HttpOnly cookie, logout, registration according to the site's `registration_mode`, email verification, and password selection. Registration modes `closed`, `require_application`, and `require_invitation` SHALL show localized states rather than a generic failure. Verification and reset tokens SHALL be read from their path segments and removed from history after use. Confirmation SHALL precede a separate login.

#### Scenario: Email ownership confirmation
- **WHEN** an email owner opens `/verify_email/:token` and submits a valid password
- **THEN** the application verifies the token, replaces the history entry with a token-free route, and offers login after success without claiming an automatic session

#### Scenario: Closed registration
- **WHEN** the site reports `registration_mode` of `closed`
- **THEN** the registration form is unavailable and the interface shows a localized closed-registration explanation

#### Scenario: Session expires
- **WHEN** an authenticated operation returns 401
- **THEN** the application clears protected visible state and offers reauthentication without silently retrying the mutation

### Requirement: Posts comments and editing
The application SHALL display Lemmy posts and their comments, allow authorized creation, reply, editing, deletion, voting, saving, reading, hiding, and reporting. Posts and comments SHALL be decoded as distinct DTOs. The application SHALL derive authoring authority from the authenticated person's ID, the post or comment `creator_id`, `can_mod`, and the viewer's community moderation or site-admin roles. It SHALL NOT rely on the removed Commune `permissions` object, and it SHALL NOT invent an expected-version field because v4 does not provide one. A failed edit SHALL preserve the draft and reload the current source for comparison without automatic retry.

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
The application SHALL treat post `body`, comment `content`, person `bio`, community `sidebar`, and site text as Markdown source. It SHALL render that source through the shared sanitized Markdown renderer and SHALL NOT expect a `body_html` field. Post images and other media SHALL be uploaded through the v4 Pictrs image endpoint, and the returned `image_url` and `filename` SHALL be retained. Remote images SHALL use no-referrer behavior. Editor source SHALL never be injected as trusted HTML.

#### Scenario: Upload fails
- **WHEN** an image upload is rejected or unavailable
- **THEN** the editor retains the unsent text, identifies the failed file, and does not insert a fabricated URL

#### Scenario: Markdown contains unsupported HTML
- **WHEN** a post body contains script, event-handler attributes, or an unsafe URL scheme
- **THEN** the renderer omits the unsafe content while preserving the surrounding readable text

### Requirement: Profiles search and notifications
The application SHALL provide public profiles through the v4 person endpoint by username, own-profile editing through the account and user-settings endpoints, avatar and banner uploads through the account image endpoints, and Markdown biography authoring. Search SHALL use the v4 search endpoint with `search_term`, `type_`, `listing_type`, and cursor navigation; the migrated interface SHALL support post and community search. Notifications SHALL be listed through the account notification endpoint, unread counts through the unread-counts endpoint, and read state through the per-notification and mark-all-read endpoints.

#### Scenario: Profile save preserves source
- **WHEN** an authenticated reader edits the biography and saves settings
- **THEN** the request receives the edited Markdown source and a rejected save retains the unsent biography

#### Scenario: Search a community
- **WHEN** a reader searches for a community name
- **THEN** the request uses the v4 search endpoint with the community type and renders only returned communities

#### Scenario: Mark all notifications read
- **WHEN** an authenticated reader marks all notifications read
- **THEN** the application calls the v4 mark-all endpoint and refreshes the unread counts without inventing a snapshot cursor

### Requirement: Community creation and management
The application SHALL support community creation with `name`, `title`, `sidebar`, `summary`, `nsfw`, `posting_restricted_to_mods`, `visibility`, discussion languages, and vote modes. Authorized managers SHALL edit those fields, manage moderators, manage community bans, approve or reject pending follows, and open community-scoped reports and modlog entries. Management authority SHALL not imply membership or posting permission. The application SHALL use `can_mod` and the authenticated account's moderator/admin records to gate actions.

#### Scenario: Manager has no posting membership
- **WHEN** community permissions permit management but prohibit posting
- **THEN** management tools are available while the compose action remains unavailable

#### Scenario: Follow approval changes membership
- **WHEN** a manager approves a pending follow request
- **THEN** the application refreshes the pending queue and reflects the returned follow state

#### Scenario: Community moderation scope
- **WHEN** a community manager opens reports or modlog for the managed community
- **THEN** only that community's review controls are available and site-wide controls remain unavailable without site-admin authority

### Requirement: Voting and content state
The application SHALL expose upvote, downvote, and clear-vote actions through one merged vote control on each post and comment. It SHALL display the net score from `score`, expose the selected direction from `vote_is_upvote`, and submit `is_upvote: true`, `false`, or `null`. Repeating the selected direction SHALL clear the vote. A direction disabled by the community's vote mode SHALL not be offered as a new mutation, but an existing vote in that direction SHALL remain clearable. The application SHALL derive saved, read, hidden, and vote state from `post_actions` and `comment_actions`.

#### Scenario: Switch from upvote to downvote
- **WHEN** a reader who has upvoted a post chooses downvote
- **THEN** the application sends `is_upvote: false` and displays the refreshed score, upvotes, and downvotes

#### Scenario: Clear an existing vote after a direction is disabled
- **WHEN** a community disables downvotes while the reader has an existing downvote
- **THEN** the application does not offer a new downvote but still permits clearing the existing vote

#### Scenario: Personal hide is distinct from moderation removal
- **WHEN** a reader hides a post
- **THEN** the interface reports the post as hidden for that account and does not describe it as removed by a moderator

### Requirement: Comment tree presentation
The application SHALL decode comments with `path` and `child_count`, build the visible reply tree from the path segments, and display the returned hierarchy. It SHALL paginate root comments with the v4 cursor, preserve sibling ordering returned by the server, and allow readers to collapse or expand descendants without issuing duplicate requests for already loaded content. A comment filtered out by the server SHALL not be reconstructed from client-side assumptions.

#### Scenario: Deep reply tree
- **WHEN** a root comment has descendants at several path depths
- **THEN** the application renders the returned hierarchy and does not replace descendants with a second flat-fetch requirement

#### Scenario: Reply sorting changes
- **WHEN** a reader selects a supported comment sort
- **THEN** the root comment request includes that sort and the rendered sibling groups follow the returned order

#### Scenario: Comment path is malformed
- **WHEN** a comment path cannot be split into integer segments
- **THEN** the interface renders the comment at the root level and does not crash the discussion

### Requirement: Community follow lifecycle
The application SHALL display `community_actions.follow_state`, `followed_at`, `blocked_at`, and the community's subscriber counts without assuming a count is publicly visible. It SHALL offer follow or unfollow according to the current state. `pending`, `accepted`, `approval_required`, and `denied` states SHALL be distinguished. A private community SHALL show the pending state without claiming read access before approval.

#### Scenario: Approval-required follow
- **WHEN** a reader follows a private community
- **THEN** the interface shows the returned pending or approval-required state and does not claim membership or read access

#### Scenario: Restricted follower count
- **WHEN** the backend omits or zeroes a subscriber count for a restricted viewer
- **THEN** the interface does not infer or fabricate the actual count

### Requirement: Account collections and personal blocks
The application SHALL provide bookmarkable cursor-paginated views for saved, read, hidden, and liked posts through the v4 account endpoints. Each view SHALL use the standard post representation and current action state. The application SHALL let an authenticated account list, add, and remove personal blocks for persons and communities by integer ID and for instance person/community blocks through the instance endpoints. It SHALL distinguish personal blocks from site-administrator bans and SHALL refresh visible lists after successful changes.

#### Scenario: Saved list after access loss
- **WHEN** a saved post is no longer readable by the account
- **THEN** the backend omits it and the interface does not retain its title, body, author, or counts in the refreshed page

#### Scenario: Block a community
- **WHEN** an account adds a valid community block
- **THEN** the block appears in the account list and content filtered by the backend disappears on the next read without changing other accounts' views

#### Scenario: Site-wide ban is not implied
- **WHEN** a reader creates a personal person or community block
- **THEN** the interface does not describe the target as banned for the whole site

### Requirement: Reporting and moderation feedback
The application SHALL let authenticated readers report readable posts, comments, and communities with a reason of 1 to 1000 Unicode code points. It SHALL use the report endpoint matching the target type and SHALL not offer self-reporting. Authorized managers and administrators SHALL list reports with the unified v4 report endpoint and resolve or reject them through the endpoint matching the report type, with an optional conclusion. The application SHALL NOT offer person reporting until a v4 person-report endpoint exists.

#### Scenario: Report submission
- **WHEN** a reader submits a valid report for a readable post
- **THEN** the application reports success without exposing private moderation state and does not imply that the report is resolved

#### Scenario: Conflicting resolution
- **WHEN** a reviewer resolves a report that another reviewer already resolved differently
- **THEN** the interface reports a conflict and refreshes the report state instead of claiming success

### Requirement: Moderation history and community bans
The application SHALL display v4 modlog pages in the backend's order with optional community and action filtering and cursor navigation. Authorized managers SHALL create and remove community bans by resolved person ID with a reason and optional Unix-epoch expiry. The application SHALL not claim an active-ban inventory or editable moderation log.

#### Scenario: Community ban expires
- **WHEN** a community ban is created with an expiry
- **THEN** the interface presents the expiry as the ban end and does not offer an edit operation not provided by the API

#### Scenario: Moderation log remains read-only
- **WHEN** a reviewer views moderation history
- **THEN** entries are displayed without edit or delete controls

#### Scenario: Ban target cannot be resolved
- **WHEN** a manager supplies an actor that does not resolve to a person
- **THEN** the interface reports a localized unresolved-actor failure and does not invent an ID

### Requirement: Notification target routing
The application SHALL decode the v4 `NotificationView` and its `Notification` fields, including `kind`, `read`, `creator_id`, `post_id`, `comment_id`, `private_message_id`, and `modlog_id`. It SHALL route reply and mention notifications to the referenced post or comment, SHALL route mod-action notifications to the moderation log when the viewer is authorized, and SHALL treat private-message notifications as display-only while private messages remain out of scope. Mark-read SHALL use the per-notification endpoint; mark-all-read SHALL use the v4 mark-all endpoint.

#### Scenario: Reply notification
- **WHEN** a notification references a comment and post
- **THEN** the interface links to the comment within the post discussion and marks the notification read through the v4 endpoint

#### Scenario: Mod-action notification
- **WHEN** a notification references a modlog entry
- **THEN** the interface identifies it as a moderation event and does not construct a post URL from the modlog ID

#### Scenario: Private-message notification is out of scope
- **WHEN** a notification references a private message
- **THEN** the interface displays it as unavailable in this change and does not route to an unimplemented private-message page

### Requirement: Password reset and change
The application SHALL provide a generic password-reset request flow, a token-based reset confirmation flow at `/password_change/:token`, and an authenticated password-change form. Reset requests SHALL not reveal whether an email belongs to an account. Reset confirmation SHALL remove the token from browser history after capture. Password change SHALL require the current password, preserve the current session on success, and clear password fields after completion.

#### Scenario: Unknown reset email
- **WHEN** a user requests a password reset for an address with no matching account
- **THEN** the interface shows the same generic acceptance state used for a known address

#### Scenario: Password reset confirmation
- **WHEN** a user opens a valid reset link and submits a valid new password
- **THEN** the application consumes the token, removes it from history, and directs the user to log in again

#### Scenario: Password change fails
- **WHEN** an authenticated password change is rejected
- **THEN** the form retains the selected fields as appropriate for correction, reports the localized failure, and does not claim that other sessions were revoked

### Requirement: Contract fidelity and secure transport
Browser requests SHALL use same-origin `/api/v4` endpoints, HttpOnly session cookies, and no CSRF header. The application SHALL never store the JWT in browser storage, SHALL handle 400/401/403/404/405/409/429/503 and network failures, and SHALL prevent stale responses from repopulating protected state after logout. A confirmed required API gap SHALL stop further feature implementation and be reported to the user before work resumes; the backend SHALL remain unchanged except for the explicitly agreed login/logout cookie contract.

#### Scenario: Required backend capability is missing
- **WHEN** implementation establishes that a required workflow cannot use an existing v4 endpoint
- **THEN** work stops with the missing contract, evidence, and affected workflow reported, without mock production behavior or unplanned backend edits

#### Scenario: Stale response after logout
- **WHEN** a protected response arrives after the session has been cleared
- **THEN** the application discards it and does not repopulate protected state

### Requirement: Removed Commune-only management operations
The application SHALL NOT present community member rosters, submission review, removal queues, context backfill, or person reports unless the v4 backend exposes a supported contract. These workflows SHALL be reported as backend dependencies rather than simulated with client-side data.

#### Scenario: Member roster is requested
- **WHEN** a manager opens a community member roster
- **THEN** the interface explains that the v4 API does not expose a member list for this migration and does not infer members from followers or moderators

#### Scenario: Submission review is requested
- **WHEN** a manager looks for the former submission or removal queue
- **THEN** the interface does not present an empty fabricated queue and reports the missing backend contract
