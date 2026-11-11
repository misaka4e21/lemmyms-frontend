## 1. Contract and ports

- [ ] 1.1 Extend `Lemmy.Domain` with the complete local-user settings fields, TOTP responses, login tokens, settings backup, invitations, captcha, and registration outcomes, and verify decoder tests cover present and absent optional fields.
- [ ] 1.2 Add narrow download and theme ports, including bootstrap handlers, and verify the browser test observes the download filename and document theme attribute.
- [ ] 1.3 Add account endpoint helpers for settings save, avatar and banner upload/delete, TOTP, login list, deletion, backup, invites, captcha, and donation state.

## 2. Settings surface

- [ ] 2.1 Replace the profile-only settings form with grouped identity, appearance, content display, notification, language, keyword, and vote fields, and verify a full save request and reload.
- [ ] 2.2 Add avatar and banner uploads to the settings surface and verify both multipart endpoints and the refreshed images.
- [ ] 2.3 Apply the server theme through the document attribute with browser and dark variants, and verify the selected theme after reload.
- [ ] 2.4 Preserve unsaved form values on validation or save failure and verify clearing an optional identity field.

## 3. Security and sessions

- [ ] 3.1 Add TOTP setup, enabling, and removal with the provisioning URI and token validation, and verify success, invalid token, and cancellation paths.
- [ ] 3.2 Add login history from the account endpoint and verify the timestamp, IP, and user-agent rendering.
- [ ] 3.3 Add the account deletion dialog with password and content choice, clear the session on success, and verify cancellation sends no request.
- [ ] 3.4 Keep the existing password-change flow reachable from the security section and verify it remains session-preserving.

## 4. Backup and invitations

- [ ] 4.1 Add settings export, settings import, and data export controls, and verify raw JSON download, opaque import submission, and malformed-file failure.
- [ ] 4.2 Add invitation listing, creation with optional maximum uses and expiry, and revocation with confirmation, and verify the request bodies and refreshed list.

## 5. Registration and prompt

- [ ] 5.1 Branch registration on closed, application-required, invitation-required, email-verification, and open modes, and verify each outcome.
- [ ] 5.2 Add the application question, invite-token field, captcha image and audio, UUID, answer, and refresh behavior, and verify failure and refresh paths.
- [ ] 5.3 Add the due donation prompt, mark-shown request, and session-local dismissal, and verify it does not repeat on the next route.

## 6. Localization and verification

- [ ] 6.1 Add the new Fluent keys to all three catalogs, regenerate the Elm bindings and hashed JSON, and verify `npm run i18n:check`.
- [ ] 6.2 Add browser fixtures and tests for settings save, theme, uploads, TOTP, login history, deletion, backup, invitations, registration modes, captcha, and the donation prompt.
- [ ] 6.3 Run `npm run compile`, `npm test`, and `npm run test:browser` with the real backend where safe, and record exact results and any environment-limited checks.
- [ ] 6.4 Run `openspec validate complete-account-settings-and-security --strict` and verify no artifact or scenario errors.
