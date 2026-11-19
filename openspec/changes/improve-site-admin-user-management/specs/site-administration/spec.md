# Spec Delta

## ADDED Requirements

### Requirement: Administration navigation tabs
The site administration workspace SHALL present its existing destinations as a tab-style navigation with a selected state. Each tab SHALL retain its independent destination URL and SHALL not combine administration content into a single route.

#### Scenario: Select another administration section
- **WHEN** an administrator selects a management tab
- **THEN** the application navigates to that section's existing independent URL and marks that tab selected

#### Scenario: Open an administration URL directly
- **WHEN** an administrator opens or reloads an administration section URL directly
- **THEN** the corresponding tab is selected and that section is rendered

### Requirement: Search current-site users by username or email
The current-site user inventory SHALL support case-insensitive partial search by username or email through server-side filtering. Search SHALL be scoped to the current tenant and compose with supported user filters and cursor pagination.

#### Scenario: Search by username
- **WHEN** an administrator searches for a username fragment
- **THEN** the inventory displays current-site users whose usernames match the fragment without case sensitivity

#### Scenario: Search by email
- **WHEN** an administrator searches for an email fragment
- **THEN** the inventory displays current-site users whose email addresses match the fragment without case sensitivity

#### Scenario: Search has no matches
- **WHEN** no current-site user matches the submitted search
- **THEN** the inventory shows its localized empty state and does not substitute unfiltered users

#### Scenario: Search is paginated
- **WHEN** an administrator moves between pages of search results
- **THEN** the search term and supported filters remain applied to the server request

### Requirement: Administrator user detail
The site administration workspace SHALL provide a dedicated detail destination for each listed current-site user. The detail view SHALL display the returned account information, link to the user's existing public profile, and provide supported management operations, including administrator assignment and username change. Access SHALL be restricted to administrators of the current tenant, and detail reads SHALL be scoped to that tenant.

#### Scenario: Administrator opens a listed user's detail
- **WHEN** an authorized site administrator selects a user in the inventory
- **THEN** the application opens that user's administrator detail view with the current account information and supported management actions

#### Scenario: Non-admin opens administrator detail
- **WHEN** an unauthenticated or non-admin reader opens an administrator user detail URL
- **THEN** the application requests login or shows a localized forbidden state without issuing an administrator detail read

#### Scenario: Administrator requests a user from another tenant
- **WHEN** a site administrator requests a person who is not a local user of the current tenant
- **THEN** the backend denies the read and returns no other tenant's private account information
