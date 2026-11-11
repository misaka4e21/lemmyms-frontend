## Why

The profile settings page currently edits only the display name, biography, and avatar. The v4 API exposes the rest of the account settings, two-factor authentication, login history, settings backup, invitations, captcha, and registration applications, but the client does not present them. Registration also stops at a generic mode message instead of asking the application question or collecting a captcha.

## What Changes

- Replace the profile-only settings form with a complete account settings surface for the v4 `SaveUserSettings` fields.
- Group the fields into identity, appearance, content display, notifications, languages, keyword blocking, and voting display. Include display name, email, Matrix ID, biography, bot flag, avatar and banner, theme, interface language, default listing and sort, post listing mode, time range, items per page, NSFW and media preferences, read and bot account visibility, link and animation behavior, vote visibility, private-message and email notification preferences, discussion languages, and blocking keywords.
- Add a server-backed theme choice with `browser` and `dark` variants, applied through a document attribute.
- Add TOTP setup and removal using the provisioning URI, password confirmation, login history, and account deletion with password and content-deletion choice.
- Add settings export, settings import, and user-data export. Settings backups remain opaque JSON files and are not parsed into UI state.
- Add invitation listing, creation with optional maximum uses and expiry, and revocation.
- Add registration application questions, image and audio captcha refresh, invite-token fields, and the registration outcomes for closed, application-required, invitation-required, email-verification, and open modes.
- Add an optional donation prompt that records its shown state through the account endpoint.
- Extend v4 DTOs and requests for the settings request, TOTP, login tokens, account deletion, settings backup, invitations, and captcha.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: complete account settings, registration applications, captcha, invitations, account security, settings backup, and donation prompt.
- `lemmy-api-integration`: extended settings, security, backup, invitation, and captcha DTO and request coverage.
- `accessible-material-interface`: grouped settings forms, TOTP and deletion dialogs, backup file controls, invite forms, and captcha controls.

## Impact

- Frontend modules: `src/Lemmy/Domain.elm`, `src/Feature/Profile.elm`, `src/Feature/Auth/*`, `src/App/View/Account.elm`, `src/App/Routing.elm`, `src/Ports.elm`, `src/bootstrap.js`, and a new account-settings or security feature module.
- Presentation: grouped settings sections, theme application, TOTP setup state, login list, delete-account dialog, backup controls, invitation list, captcha image and audio, and registration application fields.
- Localization: new Fluent keys and regenerated Elm bindings and hashed catalogs.
- Tests: domain decoders, settings and registration browser flows, TOTP and deletion confirmations, backup import/export, invitation lifecycle, captcha fallback, theme application, and real-backend acceptance where safe.
- Backend: no change. The implementation uses existing v4 account, auth, invite, captcha, and backup routes.
