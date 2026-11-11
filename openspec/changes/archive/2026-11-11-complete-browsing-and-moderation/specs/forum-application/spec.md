## ADDED Requirements

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
