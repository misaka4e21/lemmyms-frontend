# site-administration Specification

## Purpose

Provide a role-gated management workspace for the site resolved by the current browser authority, so administrators can operate the moderation and voting capabilities exposed by that site's API without implying deployment-wide control.

## Requirements

### Requirement: Lemmy site-administration access
The application SHALL expose site-administration destinations only when the authenticated account has `local_user.admin` set to true. Direct access without authentication SHALL request login, and direct access without the admin flag SHALL show a localized forbidden state without issuing unauthorized administration reads. Every request SHALL remain scoped to the tenant resolved from the current browser authority.

#### Scenario: Ordinary account opens administration
- **WHEN** an authenticated non-admin account opens `/admin`
- **THEN** the application denies access and does not load site settings, reports, modlog, or admin user lists

#### Scenario: Anonymous reader opens administration
- **WHEN** an anonymous reader opens a protected administration route
- **THEN** the application requests login and issues no administration request

#### Scenario: Another tenant host
- **WHEN** an administrator for one host opens another host served by the same installation
- **THEN** the application uses that host's tenant session and does not present the first tenant's administration data

### Requirement: Site default vote modes
The application SHALL display and update the current site's default post and comment upvote/downvote modes for newly created communities. It SHALL explain that these values are creation defaults and that existing communities keep their own vote modes. A successful update SHALL render the full returned site view; a rejected update SHALL preserve the submitted values and report a localized failure.

#### Scenario: Disable default downvotes
- **WHEN** an administrator disables the default post downvote mode
- **THEN** newly created communities default to that mode and existing communities are not described as changed

#### Scenario: Site update fails
- **WHEN** the site update request is rejected
- **THEN** the form retains the submitted values and does not present the update as saved

### Requirement: Report queue and resolution
The administration workspace SHALL list report rows from the unified v4 report endpoint with `unresolved_only`, optional `type_`, optional `community_id`, and cursor navigation. It SHALL display the returned report type, target, reporter, reason, creation time, and resolution state. Resolving or rejecting a report SHALL use the endpoint matching its type and SHALL refresh the queue after success or conflict.

#### Scenario: Filter unresolved post reports
- **WHEN** an administrator selects unresolved post reports
- **THEN** the request includes the unresolved and post-type filters and renders only returned rows

#### Scenario: Resolve a comment report
- **WHEN** an administrator resolves a comment report with a conclusion
- **THEN** the application calls the comment-report resolve endpoint and refreshes the queue

#### Scenario: Conflicting resolution
- **WHEN** a report was already resolved by another reviewer
- **THEN** the interface reports a localized conflict and refreshes the report state instead of claiming success

### Requirement: Moderation log
The administration workspace SHALL display paginated v4 modlog entries in the backend's order with optional community, person, and action filters supported by the endpoint. It SHALL display the returned action, moderator, target, reason, and creation time, and SHALL provide no edit or delete controls.

#### Scenario: Filter community history
- **WHEN** an administrator supplies a community filter
- **THEN** the request includes that filter and the interface does not infer a total count from the cursor response

#### Scenario: Modlog entry lacks optional detail
- **WHEN** a modlog row omits an optional target or reason
- **THEN** the interface omits that detail rather than deriving it from another record

### Requirement: Person bans
The administration workspace SHALL resolve an actor to a Lemmy person before creating or removing a site ban. It SHALL require a non-empty reason and an optional expiry expressed in the interface's date/time control and sent as Unix epoch seconds. It SHALL distinguish banning from unbanning, preserve input on validation failure, and refresh the relevant views after success.

#### Scenario: Ban a resolved person
- **WHEN** an administrator selects a resolved person, supplies a reason, and submits a ban
- **THEN** the application sends the person's integer ID and the reason to the v4 site-ban endpoint

#### Scenario: Actor cannot be resolved
- **WHEN** the supplied actor does not resolve to a person
- **THEN** the interface reports a localized unresolved-actor failure and does not invent an ID

#### Scenario: Unban a person
- **WHEN** an administrator removes a ban
- **THEN** the application sends the unban form for the same person and reports the returned outcome

### Requirement: Current-tenant management scope
The application SHALL NOT present a deployment-wide site directory, cross-tenant account directory, cross-tenant reports, or site-switching workspace. The management interface SHALL identify itself as scoped to the current host and SHALL not aggregate data from other tenants.

#### Scenario: No deployment directory
- **WHEN** a tenant administrator uses the management workspace
- **THEN** only current-host capabilities are offered and no other tenant's site or account directory is shown

#### Scenario: Unsupported cross-tenant request
- **WHEN** implementation requires a deployment-wide capability without a documented endpoint
- **THEN** that workflow remains out of scope and is reported as a backend dependency

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
