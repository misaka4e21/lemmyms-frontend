## ADDED Requirements

### Requirement: Accessible account settings forms
The account settings surface SHALL use labeled groups, persistent field labels, instructions, associated errors, and an error summary for multiple validation failures. Toggles SHALL expose their state programmatically, numeric limits SHALL announce their valid range, and keyword or language lists SHALL preserve item order and provide add/remove controls with localized names.

#### Scenario: Invalid numeric limit
- **WHEN** a reader enters an invalid items-per-page or time-range value
- **THEN** the error is associated with the field and focus remains usable

#### Scenario: Toggle state
- **WHEN** a screen reader inspects a display preference toggle
- **THEN** its checked state and localized label are exposed

### Requirement: Accessible security dialogs and backup controls
TOTP setup, login history, account deletion, and settings import SHALL use named dialogs or labeled sections with keyboard-operable controls. The deletion confirmation SHALL contain the warning and password field, SHALL not close on an accidental backdrop click, and SHALL return focus to a meaningful control after cancellation. The import control SHALL use a native file chooser. Status and errors SHALL be announced without exposing secrets or backup contents.

#### Scenario: Cancel account deletion
- **WHEN** a reader opens deletion and cancels
- **THEN** no request is sent, focus returns to the deletion trigger, and the account remains signed in

#### Scenario: Import file selection
- **WHEN** a keyboard user selects a backup file
- **THEN** the file chooser is native, the selected filename is announced, and no backup content is displayed

### Requirement: Accessible registration captcha and invitations
Captcha images SHALL have descriptive alternative text or a labeled audio alternative, the refresh control SHALL be keyboard operable, and the answer field SHALL have a persistent label. Invitation creation and revocation SHALL provide labeled fields and confirmation for revocation. Application questions SHALL be associated with the answer field.

#### Scenario: Captcha audio alternative
- **WHEN** a reader cannot use the image challenge
- **THEN** a labeled audio control plays the returned audio and the answer field remains usable

#### Scenario: Revoke invitation
- **WHEN** a reader activates revoke
- **THEN** a named confirmation appears, cancellation sends no request, and focus returns to the revoke control
