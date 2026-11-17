## ADDED Requirements

### Requirement: Local username editing
The application SHALL let an authenticated reader view and change their own username from account settings through the v4 user-settings endpoint. The form SHALL initialize from the authenticated account, explain the current site's username rules, and retain the submitted value while showing a rejected update.

#### Scenario: Change own username with federation disabled
- **WHEN** an authenticated reader changes their username to a name accepted by the current site's non-federated rules
- **THEN** the application submits the new username through user settings and refreshes the displayed account identity after success

#### Scenario: Username violates the active rules
- **WHEN** the backend rejects a username under the current site's federation setting
- **THEN** the application keeps the submitted value and presents the returned validation failure beside the username field

#### Scenario: Username is already taken
- **WHEN** the backend rejects a username because it is already in use on the site
- **THEN** the application keeps the submitted value and presents the returned duplicate-name failure without claiming the name changed

### Requirement: Federation-aware community names
The application SHALL explain the current site's local actor name rules when creating or editing a community, based on `local_site.federation_enabled`. The backend SHALL remain authoritative for validation, and the application SHALL associate rejected name updates with the relevant field while preserving the draft. A successful community rename SHALL render the returned community name and keep navigation and management state associated with that community.

#### Scenario: Create a Chinese-named community without federation
- **WHEN** federation is disabled and a reader submits a community name accepted by the backend's non-federated rules
- **THEN** the application creates the community and navigates using the returned community name

#### Scenario: Rename a community without federation
- **WHEN** an authorized manager changes a local community name to a name accepted by the backend's non-federated rules
- **THEN** the application updates the community and reflects the returned name in the current view and route

#### Scenario: Community name violates active rules or is already used
- **WHEN** community creation or rename is rejected for an invalid or duplicate name
- **THEN** the application preserves the name draft and displays the backend failure beside the name field

#### Scenario: Federation is enabled
- **WHEN** a reader creates or edits a community while federation is enabled
- **THEN** the form explains the federated naming rules and rejected names are reported from the backend without losing other form values
