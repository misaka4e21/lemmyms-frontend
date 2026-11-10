## ADDED Requirements

### Requirement: Community directory sort compatibility
The community directory SHALL request `/api/v4/community/list` with a `sort` value supported by Lemmy's `CommunitySortType` or omit the sort parameter. It SHALL NOT send `sort=top`. A successful response SHALL render the returned community page, and a rejected request SHALL show a localized failure with retry rather than an empty directory.

#### Scenario: Supported community sort
- **WHEN** a reader opens the community directory
- **THEN** the request uses a supported community sort such as `active_monthly` and the returned communities are rendered

#### Scenario: Unsupported sort is not sent
- **WHEN** the community directory request is inspected
- **THEN** it does not contain `sort=top` or another value outside the backend's community sort enum

#### Scenario: Directory request is rejected
- **WHEN** the community list endpoint rejects the request
- **THEN** the interface shows a localized failure with a retry action and does not claim the directory is empty
