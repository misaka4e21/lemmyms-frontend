# Proposal

## Why

The site administration area currently makes every destination a plain navigation link, while the site user inventory has no username or email search and no dedicated account management view. Administrators need a consistent way to move among management sections and inspect/manage a specific local user without conflating public profile information with private administrative information.

## What Changes

- Present the existing administration destinations as a tab-style navigation with a clear selected state while preserving their independent URLs.
- Extend current-site user search to find users by username and email, with server-side filtering and pagination.
- Keep the existing public profile page available and provide a separate administrator-only user detail page for private account information and management.
- Link each user in the administration inventory to the administrator-only detail page, with an entry from there to the public profile, and retain supported account management actions.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `site-administration`: Specify tab-style navigation, server-backed username/email search, and a tenant-scoped administrator user detail workflow with role-gated access and management.

## Impact

- Frontend administration navigation, site user inventory, person profile routing/rendering, and localized labels.
- Lemmy v4 admin user-list query and a tenant-scoped administrator user-detail API in `/data/xyh/code/rust/LemmyMultisite`.
- Existing current-tenant and admin authorization rules remain in force; private account data must not be exposed through public profile responses.
