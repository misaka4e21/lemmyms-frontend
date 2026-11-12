## ADDED Requirements

### Requirement: Site setup entry
The application SHALL provide `/setup` for an unconfigured current site. It SHALL use the backend's authenticated administrator setup contract and submit supported site fields. If the site is already configured or the viewer lacks authority, it SHALL show an appropriate state and SHALL NOT submit setup changes. Setup failures SHALL preserve entered values.

#### Scenario: Administrator completes setup
- **WHEN** an authenticated administrator submits valid setup settings for an unconfigured site
- **THEN** the application creates the current site configuration, reloads site state, and opens the configured site

#### Scenario: Setup already completed
- **WHEN** a visitor opens `/setup` for a configured site
- **THEN** the application explains that setup is complete and offers navigation to the site

### Requirement: Federation and legal entry points
The application SHALL provide direct-loadable `/instances` and `/legal` routes. Instances SHALL display backend-returned federation records and supported filters and pagination. Legal information SHALL use the current site's legal text and show an empty state when absent. `/activitypub/externalInteraction` SHALL accept a `uri`, resolve it through the v4 object resolver, and navigate to a supported local object; invalid, inaccessible, and unsupported results SHALL display a recoverable error.

#### Scenario: Remote community interaction
- **WHEN** a visitor opens the external interaction route with a resolvable community URI
- **THEN** the application opens the resolved community using its local route

#### Scenario: Invalid remote object
- **WHEN** resolution fails or returns an unsupported object
- **THEN** the application displays an error without navigating to an invented route

### Requirement: OAuth login and callback
The application SHALL offer configured OAuth providers and support `/oauth/callback`. It SHALL validate a fresh, single-use state tied to the initiating provider and redirect URI before exchanging a callback code through v4. It SHALL handle registration details and application answers required by the backend, restore the session after success, clear transient callback data, and report invalid, expired, denied, or failed callbacks without claiming login succeeded.

#### Scenario: Valid OAuth callback
- **WHEN** a callback contains the code and the matching unexpired state from an initiated login
- **THEN** the application exchanges the code, restores the authenticated session, and removes transient callback data

#### Scenario: Mismatched callback state
- **WHEN** the callback state is absent, expired, reused, or differs from the initiated state
- **THEN** the application rejects it without exchanging the code

### Requirement: Pending follows workspace
The application SHALL provide `/pending_follows` to authorized community moderators and site administrators. It SHALL list pending requests with supported cursor and filter controls and reuse community follow approval or rejection. A moderator SHALL see only backend-authorized communities; an administrator SHALL be able to request all communities. Success and stale-request errors SHALL refresh the queue.

#### Scenario: Moderator reviews a request
- **WHEN** a moderator approves a pending request for a managed community
- **THEN** the application submits the community and follower identifiers and refreshes the queue

#### Scenario: Unauthorized visitor
- **WHEN** a visitor without moderation authority opens the queue
- **THEN** the application displays an access state and does not submit review actions
