## ADDED Requirements

### Requirement: Current site configuration workspace
The administrator workspace SHALL provide supported current-site settings including identity, description, legal text, registration, federation, content policy, languages, rate limits, and site media. It SHALL initialize fields from server data, preserve untouched fields and edits on failure, validate inputs, and reload current site state after success. Existing vote settings, reports, moderation log, and bans SHALL remain available.

#### Scenario: Update site settings
- **WHEN** an administrator edits a supported setting and saves it
- **THEN** the application sends the corresponding v4 site update and displays the returned current-site state

#### Scenario: Denied site update
- **WHEN** the backend rejects an update
- **THEN** the application retains the draft and displays the failure

### Requirement: Registration application review
The application SHALL provide `/registration_applications` for current-site administrators, showing application details, supported filters and cursor navigation. It SHALL allow approval or rejection with the backend-supported denial reason, refresh after a decision or conflict, and preserve a failed decision's input. Other users SHALL not receive review controls.

#### Scenario: Reject an application
- **WHEN** an administrator rejects an application with a reason
- **THEN** the application sends the decision and refreshes the queue

### Requirement: Site administration collections
The administrator workspace SHALL support listing and managing taglines, custom emoji, and OAuth providers using the backend-supported fields and operations. It SHALL provide current-site user and media inventories with supported filters and pagination, administrator assignment where authorized, and supported permanent purge operations for people, communities, posts, and comments. It SHALL require explicit confirmation identifying the target before irreversible actions, refresh affected data after success, and display authorization or validation failures.

#### Scenario: Purge confirmation
- **WHEN** an administrator selects a supported purge action
- **THEN** the application identifies the target and requires confirmation before sending the purge request

#### Scenario: Provider secret handling
- **WHEN** an administrator edits an OAuth provider
- **THEN** an omitted secret remains unchanged and the interface does not invent or reveal an existing secret

### Requirement: Federation policy administration
Administrators SHALL inspect current-site federation records and use the backend's allow and block operations with their supported parameters. The application SHALL distinguish these site-wide policies from personal instance blocks and refresh the displayed policy after a successful change.

#### Scenario: Update federation policy
- **WHEN** an administrator changes a supported instance policy
- **THEN** the application submits the relevant current-site request and reloads the policy state
