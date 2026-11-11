## ADDED Requirements

### Requirement: Private message composition and inbox
The application SHALL let an authenticated reader start a private message to another person and read received messages through the notification feed. The composer SHALL send the message content and recipient identifier and SHALL preserve the draft when sending fails. The message list SHALL show received messages with mark-read, reply, edit, delete, and report actions only when the viewer's ownership and the message state allow them. The application SHALL NOT claim a sent box or conversation history that the API does not provide.

#### Scenario: Compose from a profile
- **WHEN** an authenticated reader chooses to send a message from another person's profile
- **THEN** the composer opens for that person and a successful send is confirmed without claiming the message appears in a sent box

#### Scenario: Messages filter
- **WHEN** a reader opens `/notifications?kind=messages`
- **THEN** the notification list shows private messages and hides reply, mention, and moderation notifications

#### Scenario: Reply to a message
- **WHEN** a reader replies to a received message
- **THEN** the composer opens with the message creator as the recipient and the same content rules as a new message

#### Scenario: Mark a message read
- **WHEN** a reader marks an unread private-message notification read
- **THEN** the notification endpoint is called and the visible unread state is refreshed

#### Scenario: Edit and delete by owner
- **WHEN** the signed-in reader created the visible message
- **THEN** edit and delete actions are available, and a successful change refreshes the message state

#### Scenario: Delete and report by recipient
- **WHEN** the signed-in reader received the visible message
- **THEN** delete and report actions are available, and editing is not offered

#### Scenario: Disabled or refused message
- **WHEN** private messages are disabled or the backend refuses the send
- **THEN** the composer shows a localized failure, keeps the draft, and does not report success

### Requirement: Private message reports
The application SHALL let a message recipient report a received message with a reason of 1 to 1000 Unicode code points. Authorized administrators SHALL see private-message reports in the report workspace and resolve or reject them with an optional conclusion. The report SHALL NOT be shown to the message sender as moderation state.

#### Scenario: Report a message
- **WHEN** a recipient submits a valid reason for a received message
- **THEN** the private-message report endpoint receives the message identifier and reason and the interface does not claim the report is resolved

#### Scenario: Resolve a message report
- **WHEN** an administrator resolves or rejects a private-message report
- **THEN** the matching resolve endpoint receives the report identifier, resolution, and optional conclusion

#### Scenario: Report permission
- **WHEN** a reader who is neither the recipient nor an administrator opens the message report controls
- **THEN** the report action is not offered

### Requirement: Multi-community directory
The application SHALL provide `/multi_communities` with local, all, and subscribed listing choices, supported sorts, text search, and cursor pagination. Each entry SHALL link to its multi-community and the directory SHALL offer a creation entry point. Empty, loading, and failed states SHALL remain distinct.

#### Scenario: Browse multi-communities
- **WHEN** a reader opens the multi-community directory
- **THEN** the list uses the default local listing and subscriber sort and renders the returned page

#### Scenario: Change filters
- **WHEN** a reader changes listing type, sort, or search text
- **THEN** the request starts a new cursor sequence with those values and the URL reflects the selection

#### Scenario: Empty directory
- **WHEN** the directory response has no items
- **THEN** the interface shows a localized empty state instead of a failed request or fabricated entries

### Requirement: Multi-community creation and settings
The application SHALL provide `/create_multi_community` for name, title, summary, and sidebar. The owner or a site administrator SHALL be able to open `/m/:name/settings`, edit those fields, mark the multi-community deleted or restored, and add or remove member communities. Adding a community SHALL use community search, and the backend's 50-entry limit SHALL appear as a localized failure.

#### Scenario: Create a multi-community
- **WHEN** an authenticated reader submits a valid name and optional metadata
- **THEN** the create request carries those fields and success opens the new `/m/:name` route

#### Scenario: Edit metadata
- **WHEN** an authorized owner changes the title, summary, or sidebar and saves
- **THEN** the edit request carries the multi-community identifier and changed fields and the detail refreshes from the response

#### Scenario: Delete and restore
- **WHEN** the owner marks the multi-community deleted or restores it
- **THEN** the edit request carries the requested deleted state and the visible management state follows the response

#### Scenario: Add a member community
- **WHEN** the owner selects a community from search results
- **THEN** the entry request carries the multi-community and community identifiers and the member list refreshes

#### Scenario: Entry limit reached
- **WHEN** the backend rejects an entry because the 50-community limit is reached
- **THEN** the interface shows a localized limit failure and does not add a fabricated row

#### Scenario: Unauthorized management
- **WHEN** a reader who is neither the creator nor a site administrator opens the settings route
- **THEN** the management form is unavailable and no mutation is sent

### Requirement: Multi-community detail and feed
The application SHALL provide `/m/:name` with the multi-community title, summary, sidebar, owner, subscriber counts, member communities, follow state, and a post feed scoped to that multi-community. A signed-in reader SHALL be able to follow or unfollow it. A remote multi-community whose follow is pending SHALL show that state without claiming membership.

#### Scenario: Load by name
- **WHEN** a reader opens `/m/:name` directly
- **THEN** the detail request uses the name and the returned member communities are shown

#### Scenario: Multi-community feed
- **WHEN** the detail page loads its posts
- **THEN** the post request is scoped to the multi-community name and uses the selected sort, time range, and cursor

#### Scenario: Follow a local multi-community
- **WHEN** a signed-in reader follows a local multi-community
- **THEN** the follow request is accepted and the refreshed detail shows the followed state

#### Scenario: Follow a remote multi-community
- **WHEN** a signed-in reader follows a remote multi-community
- **THEN** the refreshed state shows pending without claiming access or membership

#### Scenario: Unavailable multi-community
- **WHEN** the detail request returns not-found or forbidden
- **THEN** the page shows a localized unavailable state and does not render an empty feed as if the multi-community existed
