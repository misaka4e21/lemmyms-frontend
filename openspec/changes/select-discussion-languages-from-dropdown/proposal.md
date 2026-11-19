# Proposal

## Why

Several forms ask readers or administrators to enter discussion language IDs as comma-separated numbers. This makes valid languages difficult to identify and configuration error-prone across account, community, and site settings.

## What Changes

- Replace free-form discussion language ID fields with a consistent dropdown multi-select in account settings, community creation, community management, and site configuration. Opening the field reveals labeled checkbox options so readers can select multiple languages.
- Populate options from Lemmy's `all_languages` catalog returned by `GET /api/v4/site`.
- Preserve selected IDs, including configured IDs absent from the current catalog, and keep existing integer-array request payloads.
- Leave the separate interface display-language selector unchanged.

## Capabilities

### New Capabilities

### Modified Capabilities
- `forum-application`: Define discussion language selection behavior in account settings and community creation and management.
- `site-administration`: Define discussion language selection behavior in site configuration.

## Impact

- Shared Lemmy site response decoding and language selection UI/state.
- `src/Feature/AccountSettings.elm`, `src/Feature/CommunityCreate.elm`, `src/Feature/CommunityManage/*`, and `src/Feature/SiteConfiguration.elm`.
- Existing v4 account, community, and site update payloads remain integer `discussion_languages` arrays.
