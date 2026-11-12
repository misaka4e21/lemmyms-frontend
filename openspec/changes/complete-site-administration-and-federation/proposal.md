## Why

The frontend lacks site setup, several administration tools, and federation entry points available in Lemmy. Administrators and readers need these workflows within the current tenant while preserving the existing v4 and permission boundaries.

## What Changes

- Add setup and current-site administration for site settings, registration applications, users, media, federation policy, taglines, emoji, OAuth providers, and supported purge actions.
- Add public instances and legal pages, OAuth login and callback, and the external interaction entry point.
- Add a cross-community pending-follow queue for authorized moderators and administrators, reusing existing community review actions.
- Preserve existing reports, modlog, bans, and vote settings; restrict operations to backend-authorized current-site scope.
- Verify setup and destructive workflows against isolated fixtures and the current LemmyMultisite v4 contract.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: setup, public federation pages, OAuth login, external interaction, and pending-follow navigation.
- `site-administration`: current-site management workspaces and registration review.
- `lemmy-api-integration`: v4 transport and decoding for the new workflows.
- `accessible-material-interface`: accessible, localized administration and federation workflows.

## Impact

Elm routing, session handling, domain decoders, API requests, administration features, localization, and browser tests will change. Backend source and lemmy-ui are contract references; deployment-wide site management remains outside this change.
