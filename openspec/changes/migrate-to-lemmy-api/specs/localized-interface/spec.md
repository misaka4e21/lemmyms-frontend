## ADDED Requirements

### Requirement: Localized v4 error outcomes
Every migrated Lemmy v4 error outcome SHALL be presented through a complete localized message. The application SHALL map known `error` codes to catalog entries, SHALL use a generic localized failure for unknown codes, and SHALL NOT render backend `message` prose as interface copy. Validation, unauthenticated, forbidden, not-found, conflict, rate-limited, and unavailable outcomes SHALL remain distinguishable.

#### Scenario: Known error code
- **WHEN** a v4 request returns a known error such as `incorrect_login` or `not_logged_in`
- **THEN** the interface shows the corresponding localized message and does not display the raw code or server prose

#### Scenario: Unknown error code
- **WHEN** a v4 request returns an error code absent from the active catalog
- **THEN** the interface shows a generic localized failure and preserves the unsent form state

### Requirement: Path token handling
Verification and password-reset tokens SHALL be read from their Lemmy path segments, used only for the corresponding confirmation request, and removed from visible interface text. After a token is consumed or rejected, the application SHALL replace the history entry with a token-free route when the browser permits it. Tokens SHALL NOT be placed in browser storage, analytics, or user-visible error messages.

#### Scenario: Email verification link
- **WHEN** a reader opens `/verify_email/:token`
- **THEN** the application submits the path token for verification and replaces the history entry with a token-free route after completion

#### Scenario: Password reset link
- **WHEN** a reader opens `/password_change/:token` and submits a new password
- **THEN** the application consumes the path token, clears the password fields, and directs the reader to sign in again

#### Scenario: Invalid token
- **WHEN** a verification or reset token is rejected
- **THEN** the interface shows a localized invalid-or-expired message without echoing the token
