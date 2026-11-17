## ADDED Requirements

### Requirement: Site administrator username changes
The site user-management interface SHALL let an authorized site administrator change a user's username through the v4 administrator username endpoint. The interface SHALL identify the target user, explain the current site's username rules, and preserve the draft while presenting backend validation, duplicate-name, hierarchy, or authorization failures. It SHALL refresh the affected user identity after a successful change.

#### Scenario: Administrator changes a username with federation disabled
- **WHEN** an authorized site administrator submits a target user's new username accepted by the current site's non-federated rules
- **THEN** the application sends the target person ID and username and displays the updated username after success

#### Scenario: Administrator submits a conflicting or invalid username
- **WHEN** the backend rejects an administrator's username change for an invalid or duplicate name
- **THEN** the interface preserves the draft and identifies the failure without updating the displayed user identity

#### Scenario: Administrator lacks permission for the target
- **WHEN** the backend rejects the change because the administrator cannot manage the target account or the target is outside the current site
- **THEN** the interface reports the failure and does not display the change as successful

#### Scenario: Federation is enabled
- **WHEN** an administrator changes a username while federation is enabled
- **THEN** the interface explains the federated naming rules and displays any backend validation failure while retaining the draft
