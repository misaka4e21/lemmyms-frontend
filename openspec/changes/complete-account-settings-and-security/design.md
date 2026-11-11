## Context

See `proposal.md` for motivation. The v4 account response already includes the full local-user settings, keyword blocks, discussion languages, and account flags. The settings save endpoint accepts optional fields, and the security, backup, invitation, captcha, and deletion routes already exist. The current profile form edits only a small subset and discards the rest on save.

## Goals / Non-Goals

**Goals:**

- Present every supported account setting with a stable server round trip.
- Keep security secrets and backup contents out of browser storage.
- Reuse the existing account, auth, invite, and captcha endpoints.
- Make registration modes explicit instead of falling back to a generic message.

**Non-Goals:**

- Admin review of registration applications; that remains in site administration.
- Private-message inbox or multi-community settings.
- Parsing or editing settings backups in the client.
- QR image generation for TOTP. The provisioning URI is shown for manual entry.

## Decisions

### Settings model and save

A dedicated account-settings feature owns one form model initialized from `MyUserInfo.localUserView.localUser`, `MyUserInfo.keywordBlocks`, and `MyUserInfo.discussionLanguages`. The form submits the current values for every supported field, including empty optional strings, so clearing a display name or Matrix ID is explicit. A successful save reloads `/account`; a failed save keeps the form values and reports the localized error.

The settings page groups fields into identity, appearance, content display, notifications, languages, keyword blocking, and vote display. Existing profile display-name, biography, avatar, and password controls move into these groups. The avatar and banner uploads use the account image endpoints and refresh the account after success.

### Theme application

The account theme is stored on the server. The client supports `browser` and `dark`; unknown server values fall back to `browser`. A narrow port sets `document.documentElement.dataset.theme` after the active theme changes, and CSS tokens provide the dark palette. The browser preference is not written to local storage; the server setting remains authoritative.

### Security flows

TOTP setup calls the generate endpoint, displays the returned `totp_secret_url` in a selectable code block, and enables only after a token is submitted. The secret and token remain in the local feature model and are cleared after success or cancellation. Removing TOTP requires a current token.

Login history is read-only because v4 exposes listing but no token-revocation route. Account deletion uses a named confirmation dialog with the current password and a delete-content checkbox. A successful delete clears the session and navigates to login.

### Backup and data export

Settings export downloads the raw JSON response through a narrow download port. Settings import reads the selected file as text, validates that it is a JSON object without exposing its contents, and submits the original text to the import endpoint. Data export uses a separate download action. No backup content enters browser storage or application logs.

### Invitations

The invitation section appears when the account can invite. It lists the cursor page returned by the invite endpoint and shows token, use count, maximum uses, and expiry. Creation accepts optional maximum uses and an ISO date-time expiry. Revocation requires confirmation and sends the token.

### Registration modes and captcha

The registration form branches on `registration_mode`:

- `closed` shows the closed explanation and no submit control.
- `require_application` shows the site's application question and requires an answer.
- `require_invitation` shows an invite-token field.
- Captcha, when enabled, shows the returned image and audio, stores only the UUID and answer in the form, and refreshes the challenge on request or rejection.

The response distinguishes `registration_created`, `verify_email_sent`, and an immediate session. The interface does not claim a session when the server only created an application.

### Donation prompt

When the site and account indicate a due donation prompt, the shell shows a dismissible localized notice. Dismissing it calls the mark-shown endpoint and stores only a local in-memory dismissal for the current session.

## Risks / Trade-offs

- **Clearing optional fields can wipe profile data** → Submit cleared values only after the user edits them, show the current value, and reload from the server after save.
- **TOTP secrets are sensitive** → Keep them in memory only, clear on exit, and never put them in URLs or storage.
- **Backup import is opaque** → Validate JSON shape without rewriting it; on rejection keep the current settings and report the failure.
- **Captcha audio support varies** → Keep both image and audio controls and allow refresh when either is unusable.
- **Theme support is limited to two variants** → Unknown server values fall back to `browser`; do not claim arbitrary Lemmy themes are available.
- **Deletion cannot be undone** → Require the password, a content choice, and an explicit confirmation.

## Migration Plan

1. Extend domain types and ports for settings, security, backup, invitations, captcha, and theme.
2. Build the grouped account-settings surface and move existing profile controls into it.
3. Add TOTP, login history, deletion, and password controls.
4. Add export/import, data export, and invitations.
5. Add registration application, captcha, and donation prompt handling.
6. Add Fluent keys, regenerate catalogs, and update browser and real-backend tests.
7. Roll back by reverting the change commit. No database migration is involved.
