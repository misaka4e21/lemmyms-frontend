# forum-application Specification

## Purpose

Provide a complete browser forum experience against a Lemmy v4 API while preserving server permissions, privacy, and content semantics.

## Requirements

### Requirement: Lemmy canonical navigation and discovery
The application SHALL provide bookmarkable Lemmy routes for the migrated features: `/`, `/communities`, `/c/:name`, `/c/:name/settings`, `/post/:post_id/:comment_id?`, `/comment/:comment_id`, `/create_post`, `/create_community`, `/u/:username`, `/search`, `/notifications`, `/settings`, `/admin`, `/reports`, and `/modlog/:communityId?`. It SHALL also provide `/login`, `/signup`, `/verify_email/:token`, `/password_change/:token`, and `/login_reset` for account entry. Browser back, forward, and direct loading SHALL work. Post and comment lists SHALL use v4 `page_cursor` navigation plus the supported `ListingType` and sort values. The application SHALL NOT invent totals, page numbers, or unsupported sorts.

The application SHALL generate canonical Lemmy paths for these destinations. It SHALL NOT generate or accept the former Commune route shapes `/communities/:id`, `/posts/:id`, `/posts/:id/edit`, `/profiles/:name`, `/register`, `/verify-email`, `/reset-password`, or `/reset-password/confirm`. Application-specific account, administrative, password-settings, and comment-edit destinations MAY use paths outside the Lemmy set.

`/c/:name` and `/c/:name/settings` SHALL identify the community by name. The account settings destination `/settings` SHALL open the profile settings surface.

#### Scenario: Direct post navigation
- **WHEN** a reader loads `/post/:post_id` directly and then returns to the previous list
- **THEN** the application loads the authorized post and comments and restores the list route and cursor context

#### Scenario: Empty or unavailable collection
- **WHEN** a listing is empty or its request fails
- **THEN** the interface distinguishes empty, loading, and error states and offers an appropriate retry without fabricated content

#### Scenario: Protected route without a session
- **WHEN** an anonymous reader opens an account, notification, settings, or management route
- **THEN** the application explains that authentication is required and does not issue protected reads

#### Scenario: Former Commune path
- **WHEN** a reader opens `/communities/1`, `/posts/1`, `/profiles/alice`, `/register`, or `/reset-password`
- **THEN** the application does not treat the path as a feature route and shows its localized not-found state

#### Scenario: Community name route
- **WHEN** a reader opens `/c/news` or `/c/news/settings`
- **THEN** the application resolves the community by name and uses the returned identifier for its listings and management requests

#### Scenario: Account settings route
- **WHEN** an authenticated reader opens `/settings`
- **THEN** the application renders the current profile settings instead of a not-found page

### Requirement: Comment permalink resolution
The application SHALL resolve `/comment/:comment_id` to the discussion containing that comment. It SHALL load the comment to obtain its post, replace the history entry with `/post/:post_id/:comment_id`, and display the referenced comment in the post discussion. If the comment or its post is deleted, unreadable, or missing, the application SHALL show a localized unavailable state with navigation away from the failed target and SHALL NOT fabricate a post or comment.

#### Scenario: Existing comment link
- **WHEN** a reader opens `/comment/42` and comment 42 belongs to post 10
- **THEN** the application replaces the history entry with `/post/10/42`, loads the post discussion, and focuses comment 42

#### Scenario: Unavailable comment link
- **WHEN** the comment request returns not-found, forbidden, or deleted content
- **THEN** the application shows a localized unavailable message and does not render an empty post with invented metadata

#### Scenario: Back navigation after resolution
- **WHEN** a reader follows a comment link and then presses Back
- **THEN** the application returns to the page before the comment link without replaying the comment resolution

### Requirement: Community directory sort compatibility
The community directory SHALL request `/api/v4/community/list` with a `sort` value supported by Lemmy's `CommunitySortType` or omit the sort parameter. It SHALL NOT send `sort=top`. A successful response SHALL render the returned community page, and a rejected request SHALL show a localized failure with retry rather than an empty directory.

#### Scenario: Supported community sort
- **WHEN** a reader opens the community directory
- **THEN** the request uses a supported community sort such as `active_monthly` and the returned communities are rendered

#### Scenario: Unsupported sort is not sent
- **WHEN** the community directory request is inspected
- **THEN** it does not contain `sort=top` or another value outside the backend's community sort enum

#### Scenario: Directory request is rejected
- **WHEN** the community list endpoint rejects the request
- **THEN** the interface shows a localized failure with a retry action and does not claim the directory is empty

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
### Requirement: Content discovery controls
The latest and community feeds SHALL expose listing type, post sort, time range, and post listing mode controls. The selected values SHALL be stored in the URL query, and changing a control SHALL request the first cursor page for the new combination. The application SHALL send `type`, `sort`, and `time_range_seconds` only with supported v4 values and SHALL NOT invent a time range when none is selected.

Post cards SHALL present the returned thumbnail and alt text, and SHALL present the post's community tags. A post detail SHALL present cross-posts returned by the post response. When the viewer has NSFW blur enabled, an NSFW post SHALL hide its body and media behind a labeled reveal control until the viewer opens it.

#### Scenario: Change listing type or sort
- **WHEN** a reader changes the latest feed from local to subscribed or changes the sort
- **THEN** the request uses the new `type` or `sort` and starts without a cursor

#### Scenario: Time range selection
- **WHEN** a reader selects a time range
- **THEN** the request includes the matching `time_range_seconds` and the URL keeps the selection

#### Scenario: Post listing mode
- **WHEN** a reader selects list, card, or small-card mode
- **THEN** the same posts render in the chosen layout without changing the request filters

#### Scenario: NSFW post is blurred
- **WHEN** a blurred NSFW post is shown
- **THEN** its body and media are hidden until the reader activates the localized reveal control

#### Scenario: Cross-posts
- **WHEN** a post detail response includes cross-posts
- **THEN** the discussion lists them as links to their own posts

### Requirement: Post and comment moderation controls
The application SHALL expose post removal, locking, community featuring, and comment removal, locking, and distinguishing to viewers whose post or comment response reports moderation authority. Successful actions SHALL refresh the visible content from the server. A forbidden action SHALL show a localized failure and SHALL NOT report success.

Authenticated readers SHALL be able to mark a post read, open the server-provided vote list for a post or comment, and block the post author or community. Blocking SHALL refresh the current route so the server can remove filtered content.

#### Scenario: Remove a post
- **WHEN** a moderator removes a post
- **THEN** the request sets `removed` and the refreshed card reports the removed state

#### Scenario: Distinguish a comment
- **WHEN** a moderator distinguishes a comment
- **THEN** the refreshed comment reports its distinguished state

#### Scenario: View votes
- **WHEN** a moderator opens the vote list for a post or comment
- **THEN** the dialog lists the returned voters and their vote direction

#### Scenario: Block a community
- **WHEN** an authenticated reader blocks the post's community
- **THEN** the current route reloads and the server-filtered community content is no longer claimed as visible

### Requirement: Community metadata and notifications
Community pages SHALL display the returned icon, banner, tags, moderator list, and notification mode. Community managers SHALL be able to add and remove tags, upload an icon or banner, and change the community notification mode. Tag and image changes SHALL refresh the community view from the server.

#### Scenario: Community tags
- **WHEN** a community page renders tags
- **THEN** the tags are shown as labeled values and posts may show their returned tags

#### Scenario: Add a tag
- **WHEN** a manager adds a valid tag name
- **THEN** the request creates the tag and the refreshed community lists it

#### Scenario: Upload a community image
- **WHEN** a manager uploads an icon or banner
- **THEN** the request uses the matching community image endpoint and the refreshed header shows the returned URL

#### Scenario: Change community notifications
- **WHEN** a reader changes the community notification mode
- **THEN** the request sets the mode and the refreshed community actions report it

### Requirement: Search result types
Search SHALL support all, posts, comments, communities, users, and URL-only post search. The selected type SHALL be stored in the URL and mapped to the v4 `type_` values, with URL search using `post_url_only`. Results SHALL render the returned posts, comments, communities, and persons, and SHALL show a resolved object above the lists when the server returns one. Cursor pagination SHALL preserve the selected type and query.

#### Scenario: Search comments
- **WHEN** a reader searches for comments
- **THEN** the request uses `type_=comments` and renders returned comments

#### Scenario: Search users
- **WHEN** a reader searches for users
- **THEN** the request uses `type_=users` and renders returned profiles

#### Scenario: Search a URL
- **WHEN** a reader chooses URL search
- **THEN** the request uses post type with `post_url_only=true` and renders matching posts

#### Scenario: Resolved object
- **WHEN** the search response includes a resolved object
- **THEN** the resolved object is shown before the typed result lists

### Requirement: Profile content tabs
Public profiles SHALL provide posts and comments tabs. A signed-in reader's own profile SHALL also provide saved, liked, read, and hidden tabs backed by the account collection endpoints. The active tab SHALL be stored in the URL, each tab SHALL use cursor pagination, and unavailable or forbidden collections SHALL show a localized state rather than fabricated content.

#### Scenario: Public profile comments
- **WHEN** a reader opens a profile's comments tab
- **THEN** the request uses person content with the comment type and renders returned comments

#### Scenario: Own saved posts
- **WHEN** the signed-in reader opens the saved tab on their profile
- **THEN** the request uses the account saved endpoint and renders returned posts

#### Scenario: Private collection unavailable
- **WHEN** a private collection request is forbidden
- **THEN** the tab shows a localized unavailable state and does not claim the collection is empty
### Requirement: Complete account settings
The account settings surface SHALL edit the v4 settings fields for identity, appearance, content display, notifications, languages, keyword blocking, and vote display. It SHALL include display name, email, Matrix ID, biography, bot flag, avatar and banner, theme, interface language, default listing type, post listing mode, default post and comment sorts, default time range, items per page, NSFW and media visibility, blur and animation choices, read and bot account visibility, link behavior, vote visibility, email and private-message preferences, discussion languages, and blocking keywords. A successful save SHALL reload the authenticated account. A failed save SHALL preserve the unsaved form and SHALL NOT report success.

#### Scenario: Save display preferences
- **WHEN** an authenticated reader changes the default listing type, sort, layout, and items per page and saves
- **THEN** the request carries those fields and the refreshed account reports the saved values

#### Scenario: Clear an optional identity field
- **WHEN** a reader clears the Matrix ID or display name and saves
- **THEN** the request represents the cleared value and the refreshed account reflects it

#### Scenario: Email change requires verification
- **WHEN** a reader changes the account email
- **THEN** the interface reports the server outcome and does not claim the new address is verified before confirmation

#### Scenario: Save fails
- **WHEN** the settings save is rejected
- **THEN** the form keeps the unsaved values and shows a localized error with retry

### Requirement: Account security and sessions
The account settings SHALL provide TOTP setup and removal, login history, password change, and account deletion. TOTP setup SHALL display the returned provisioning URI for manual entry, SHALL require a valid token before enabling, and SHALL NOT persist the secret in browser storage. Login history SHALL show server-returned timestamps, IP addresses, and user agents. Account deletion SHALL require the current password and an explicit delete-content choice, SHALL warn that it is irreversible, and SHALL clear the session and navigate to login after success.

#### Scenario: Enable TOTP
- **WHEN** a reader generates a TOTP secret and submits a valid token
- **THEN** the account reports TOTP enabled and the secret is not retained after the flow

#### Scenario: Invalid TOTP token
- **WHEN** the submitted token is rejected
- **THEN** the interface keeps the setup state, reports a localized failure, and does not claim two-factor authentication is enabled

#### Scenario: Delete account
- **WHEN** a reader confirms deletion with the correct password and a content choice
- **THEN** the request includes both values, the session is cleared, and the application navigates to login

### Requirement: Settings backup and data export
The account settings SHALL export the server settings backup as a JSON download and import a selected backup file. The backup SHALL be sent back as an opaque JSON document without reconstructing or editing its contents. Data export SHALL download the server-provided account data separately from the settings backup. A rejected import SHALL leave the current settings unchanged and SHALL show a localized failure.

#### Scenario: Export settings
- **WHEN** a reader requests a settings export
- **THEN** the returned backup is offered as a JSON file download

#### Scenario: Import settings
- **WHEN** a reader selects a valid backup file and imports it
- **THEN** the file's JSON is submitted to the import endpoint and the refreshed settings reflect the server result

#### Scenario: Malformed backup
- **WHEN** the selected file is not valid JSON or the server rejects the import
- **THEN** the current settings remain and the interface reports a localized failure

### Requirement: Invitations
When the site permits invitations, the account settings SHALL list the reader's invitations and SHALL allow creating and revoking them. Creation SHALL accept optional maximum uses and expiry. The list SHALL show the token or invitation link, use count, maximum uses, and expiry returned by the server. Revocation SHALL require the invitation token and SHALL refresh the list.

#### Scenario: Create invitation
- **WHEN** a reader creates an invitation with a maximum use count and expiry
- **THEN** the request carries both values and the refreshed list shows the new invitation

#### Scenario: Revoke invitation
- **WHEN** a reader revokes an invitation
- **THEN** the request carries its token and the refreshed list no longer offers it as active

### Requirement: Registration application and captcha
Registration SHALL follow the site's registration mode. In `closed` mode the form SHALL be unavailable. In `require_application` mode the form SHALL display the site's application question and require an answer. In `require_invitation` mode the form SHALL accept an invitation token. When captcha is enabled, the form SHALL show the returned image and audio, accept an answer, and refresh the challenge. The interface SHALL distinguish registration-created, verification-email-sent, and immediate-session outcomes.

#### Scenario: Application-required registration
- **WHEN** a reader submits registration while the site requires an application
- **THEN** the request includes the application answer and the interface reports that the application is pending rather than claiming an account session

#### Scenario: Captcha refresh
- **WHEN** a reader requests a new captcha
- **THEN** the image and audio and their UUID are replaced and the previous answer is not reused

#### Scenario: Invitation-required registration
- **WHEN** a reader submits registration with an invitation token
- **THEN** the request includes the token and the server outcome is shown without inventing an accepted state

### Requirement: Donation prompt
When the server reports a due donation prompt, the application SHALL show a dismissible localized prompt at most once per server interval and SHALL record that it was shown. Dismissing it SHALL NOT change account security or notification settings.

#### Scenario: Donation prompt shown once
- **WHEN** the account is due for a donation prompt and the reader dismisses it
- **THEN** the application records the shown state and does not repeat the prompt on the next route
