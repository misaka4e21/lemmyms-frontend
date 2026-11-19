# Spec Delta

## MODIFIED Requirements

### Requirement: Community creation and management
The application SHALL support community creation with `name`, `title`, `sidebar`, `summary`, `nsfw`, `posting_restricted_to_mods`, `visibility`, discussion languages, and vote modes. Authorized managers SHALL edit those fields, manage moderators, manage community bans, approve or reject pending follows, and open community-scoped reports and modlog entries. Management authority SHALL not imply membership or posting permission. The application SHALL use `can_mod` and the authenticated account's moderator/admin records to gate actions. Community permission controls and summaries SHALL reflect the API's supported `visibility` and `posting_restricted_to_mods` values; they SHALL NOT present client-only `eligible_users` or `members` policies as server-enforced access rules. Account-specific actions SHALL follow server-returned roles and action state, with rejected requests handled as authoritative permission outcomes.

#### Scenario: Manager has no posting membership
- **WHEN** community permissions permit management but prohibit posting
- **THEN** management tools are available while the compose action remains unavailable

#### Scenario: Follow approval changes membership
- **WHEN** a manager approves a pending follow request
- **THEN** the application refreshes the pending queue and reflects the returned follow state

#### Scenario: Community moderation scope
- **WHEN** a community manager opens reports or modlog for the managed community
- **THEN** only that community's review controls are available and site-wide controls remain unavailable without site-admin authority

#### Scenario: Community policy display
- **WHEN** a community card or detail page displays access information
- **THEN** it identifies visibility from the returned `visibility` and posting restriction from `posting_restricted_to_mods`, without claiming an `eligible_users` or `members` policy

#### Scenario: Community creation and management policy controls
- **WHEN** a reader creates or manages a community
- **THEN** the form exposes the API-supported visibility and moderator-only posting settings and does not submit client-only read or post policy fields
