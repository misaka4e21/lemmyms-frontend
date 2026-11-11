## ADDED Requirements

### Requirement: Complete account settings transport
The application SHALL decode the account settings fields returned by `GET /account` and SHALL send supported optional fields to `PUT /account/settings/save`. Clearing an optional text field SHALL be represented explicitly. The application SHALL use the avatar and banner upload and delete endpoints for account images and SHALL NOT place image bytes or credentials in browser storage.

#### Scenario: Settings save request
- **WHEN** a reader saves the complete settings form
- **THEN** the request contains the selected booleans, strings, numeric limits, discussion languages, and blocking keywords

#### Scenario: Banner upload
- **WHEN** a reader uploads a profile banner
- **THEN** the multipart request targets the account banner endpoint and the refreshed account uses the returned URL

### Requirement: Security and session requests
The application SHALL use `POST /account/auth/totp/generate`, `POST /account/auth/totp/edit`, `GET /account/login/list`, `DELETE /account`, and `PUT /account/auth/change_password` for the corresponding security workflows. A deletion request SHALL include the password and content-deletion choice. A successful deletion SHALL end the local session.

#### Scenario: TOTP edit request
- **WHEN** a reader enables or disables TOTP
- **THEN** the request includes the token and the requested enabled state

#### Scenario: Account deletion request
- **WHEN** a reader confirms deletion
- **THEN** the request includes the password and content-deletion boolean and a successful response clears the session

### Requirement: Backup invitation and captcha requests
The application SHALL use `GET /account/settings/export`, `POST /account/settings/import`, `GET /account/data/export`, `GET /account/invite/list`, `POST /account/invite`, `DELETE /account/invite`, and `GET /account/auth/get_captcha`. Settings import SHALL submit the selected JSON without reconstructing it. Invitation requests SHALL carry optional maximum uses and expiry. Registration SHALL carry the application answer, captcha UUID and answer, and invitation token when present.

#### Scenario: Settings import body
- **WHEN** a reader imports a backup
- **THEN** the request body is the selected JSON document and the endpoint response updates the settings state

#### Scenario: Invitation creation request
- **WHEN** a reader creates an invitation
- **THEN** the request includes the optional maximum uses and expiry

#### Scenario: Registration request
- **WHEN** a reader submits a guarded registration form
- **THEN** the request includes the answer, captcha fields, or invitation token required by the site mode
