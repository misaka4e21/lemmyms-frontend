## REMOVED Requirements

### Requirement: Current-site management access
**Reason**: Lemmy has no deployment-superadministrator role; site administration is scoped to the tenant resolved from the request host and the authenticated account's `local_user.admin` flag.
**Migration**: Use the new `Lemmy site-administration access` requirement.

### Requirement: Site vote settings
**Reason**: Lemmy exposes vote modes as per-community settings and site-level defaults for newly created communities, not as one site-wide upvote/downvote toggle pair.
**Migration**: Use the new `Site default vote modes` requirement and manage existing community vote modes in community settings.

### Requirement: Report review
**Reason**: Lemmy uses a unified report list with type-specific resolve endpoints and `unresolved_only`, `type_`, `community_id`, and cursor parameters.
**Migration**: Use the new `Report queue and resolution` requirement.

### Requirement: Moderation history
**Reason**: Lemmy returns its own `ModlogView` records and cursor pagination rather than Commune moderation entries.
**Migration**: Use the new `Moderation log` requirement.

### Requirement: Site ban actions
**Reason**: Lemmy bans a `person_id` with a boolean, reason, and Unix-epoch expiry; it does not accept an Actor URI directly.
**Migration**: Resolve the actor through v4 search or object resolution, then use the new `Person bans` requirement.

### Requirement: Deferred deployment management
**Reason**: The target backend is multi-tenant by host, but its API has no deployment-wide administrator or cross-site management contract.
**Migration**: Use the new `Current-tenant management scope` requirement.

## ADDED Requirements

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
