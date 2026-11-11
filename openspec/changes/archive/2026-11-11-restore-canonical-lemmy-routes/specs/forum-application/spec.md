## MODIFIED Requirements

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

## ADDED Requirements

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
