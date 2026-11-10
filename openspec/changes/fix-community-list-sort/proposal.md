## Why

The community directory currently sends `sort=top` to `/api/v4/community/list`, but Lemmy's `CommunitySortType` has no `top` variant. The backend rejects the request with 400, so the directory cannot load communities.

## What Changes

- Replace the unsupported `sort=top` with a supported community sort, using the backend default `active_monthly`.
- Add a mock browser assertion that the community directory request carries a supported sort value.
- Add a real-backend assertion that `/communities` renders a community created by the admin flow.
- Keep the existing listing type and cursor query parameters.

## Capabilities

### New Capabilities

### Modified Capabilities
- `forum-application`: the community directory must request a supported Lemmy community sort and must render a successful directory response instead of an empty error state.

## Impact

- `src/Feature/Community.elm` community directory request.
- `tests-browser/forum.spec.js` v4 mock coverage for the query and rendered directory.
- `tests-browser/real-backend.spec.js` real Lemmy directory regression.
