## Context

See `proposal.md` for motivation and `specs/` for user-visible behavior. The app already receives the current `LocalSite` state, exposes own account settings and community creation/management surfaces, and has a site administration workspace. The LemmyMultisite backend provides the username and community name mutations and applies federation-dependent validation, uniqueness, permission, and tenant checks.

## Goals / Non-Goals

**Goals:**

- Add the missing name fields and actions to the existing account, community, and site-user flows.
- Keep validation messages and form drafts attached to the operation that failed.
- Make the active site's federation setting understandable at each name input.

**Non-Goals:**

- Change backend validation, authorization, uniqueness, or tenant behavior.
- Rename remote actors or change a community's canonical actor identity.
- Add a deployment-wide user directory or a frontend-only bypass for backend validation.

## Decisions

- Use the existing v4 operations: user settings for self-service username changes, administrator username change for site-admin changes, and community create/update for community names. This keeps account permissions and site scope enforced by the backend.
- Use the current site's `federation_enabled` value to select the explanatory rule text. Keep the backend authoritative and surface its structured error for invalid, duplicate, or unauthorized operations; this avoids maintaining a second Unicode category implementation in Elm that could diverge from the Rust validator.
- Place each control in its existing management surface: account settings, community creation/settings, and site user management. After success, refresh the relevant account or community view so route labels and identity data stay current.
- Reuse existing localized form feedback patterns and add localized text for the rules and name-specific actions. Preserve unrelated form state on failures.

## Risks / Trade-offs

- [Rule hints may drift from backend rules] → Keep the server authoritative, derive which hint to show from the live `LocalSite` value, and cover both federation states with fixtures.
- [A username change can invalidate the current profile route] → Refresh the session identity and replace or redirect the profile route using the returned/current account name after success.
- [The current site user view may not expose enough row context for an inline editor] → Keep the change scoped to users returned by the existing site-scoped user list and use the selected row's person ID; do not add cross-tenant lookup behavior.

## Migration Plan

No data migration or backend deployment is required. Release the frontend with the existing v4 backend endpoints available. Rollback consists of reverting the frontend change; any completed name changes remain valid backend data.
