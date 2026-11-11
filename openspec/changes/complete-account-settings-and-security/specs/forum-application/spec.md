## ADDED Requirements

### Requirement: Complete account settings
The account settings surface SHALL edit the v4 settings fields for identity, appearance, content display, notifications, languages, keyword blocking, and vote display. It SHALL include display name, email, Matrix ID, biography, bot flag, avatar and banner, theme, interface language, default listing type, post listing mode, default post and comment sorts, default time range, items per page, NSFW and media visibility, blur and animation choices, read and bot account visibility, link behavior, vote visibility, email and private-message preferences, discussion languages, and blocking keywords. A successful save SHALL reload the authenticated account. A failed save SHALL preserve the unsaved form and SHALL NOT report success.

#### Scenario: Save display preferences
- **WHEN** an authenticated reader changes the default listing type, sort, layout, and items per page and saves
- **THEN** the request carries those fields and the refreshed account reports the saved values

#### Scenario: Clear an optional identity field
- **WHEN** a reader clears the Matrix ID or display name and saves
- **THEN** the request represents the cleared value and the refreshed account reflects it

#### Scenario: Email change requires verification
- **WHEN** a reader changes the account email
- **THEN** the interface reports the server outcome and does not claim the new address is verified before confirmation

#### Scenario: Save fails
- **WHEN** the settings save is rejected
- **THEN** the form keeps the unsaved values and shows a localized error with retry

### Requirement: Account security and sessions
The account settings SHALL provide TOTP setup and removal, login history, password change, and account deletion. TOTP setup SHALL display the returned provisioning URI for manual entry, SHALL require a valid token before enabling, and SHALL NOT persist the secret in browser storage. Login history SHALL show server-returned timestamps, IP addresses, and user agents. Account deletion SHALL require the current password and an explicit delete-content choice, SHALL warn that it is irreversible, and SHALL clear the session and navigate to login after success.

#### Scenario: Enable TOTP
- **WHEN** a reader generates a TOTP secret and submits a valid token
- **THEN** the account reports TOTP enabled and the secret is not retained after the flow

#### Scenario: Invalid TOTP token
- **WHEN** the submitted token is rejected
- **THEN** the interface keeps the setup state, reports a localized failure, and does not claim two-factor authentication is enabled

#### Scenario: Delete account
- **WHEN** a reader confirms deletion with the correct password and a content choice
- **THEN** the request includes both values, the session is cleared, and the application navigates to login

### Requirement: Settings backup and data export
The account settings SHALL export the server settings backup as a JSON download and import a selected backup file. The backup SHALL be sent back as an opaque JSON document without reconstructing or editing its contents. Data export SHALL download the server-provided account data separately from the settings backup. A rejected import SHALL leave the current settings unchanged and SHALL show a localized failure.

#### Scenario: Export settings
- **WHEN** a reader requests a settings export
- **THEN** the returned backup is offered as a JSON file download

#### Scenario: Import settings
- **WHEN** a reader selects a valid backup file and imports it
- **THEN** the file's JSON is submitted to the import endpoint and the refreshed settings reflect the server result

#### Scenario: Malformed backup
- **WHEN** the selected file is not valid JSON or the server rejects the import
- **THEN** the current settings remain and the interface reports a localized failure

### Requirement: Invitations
When the site permits invitations, the account settings SHALL list the reader's invitations and SHALL allow creating and revoking them. Creation SHALL accept optional maximum uses and expiry. The list SHALL show the token or invitation link, use count, maximum uses, and expiry returned by the server. Revocation SHALL require the invitation token and SHALL refresh the list.

#### Scenario: Create invitation
- **WHEN** a reader creates an invitation with a maximum use count and expiry
- **THEN** the request carries both values and the refreshed list shows the new invitation

#### Scenario: Revoke invitation
- **WHEN** a reader revokes an invitation
- **THEN** the request carries its token and the refreshed list no longer offers it as active

### Requirement: Registration application and captcha
Registration SHALL follow the site's registration mode. In `closed` mode the form SHALL be unavailable. In `require_application` mode the form SHALL display the site's application question and require an answer. In `require_invitation` mode the form SHALL accept an invitation token. When captcha is enabled, the form SHALL show the returned image and audio, accept an answer, and refresh the challenge. The interface SHALL distinguish registration-created, verification-email-sent, and immediate-session outcomes.

#### Scenario: Application-required registration
- **WHEN** a reader submits registration while the site requires an application
- **THEN** the request includes the application answer and the interface reports that the application is pending rather than claiming an account session

#### Scenario: Captcha refresh
- **WHEN** a reader requests a new captcha
- **THEN** the image and audio and their UUID are replaced and the previous answer is not reused

#### Scenario: Invitation-required registration
- **WHEN** a reader submits registration with an invitation token
- **THEN** the request includes the token and the server outcome is shown without inventing an accepted state

### Requirement: Donation prompt
When the server reports a due donation prompt, the application SHALL show a dismissible localized prompt at most once per server interval and SHALL record that it was shown. Dismissing it SHALL NOT change account security or notification settings.

#### Scenario: Donation prompt shown once
- **WHEN** the account is due for a donation prompt and the reader dismisses it
- **THEN** the application records the shown state and does not repeat the prompt on the next route
