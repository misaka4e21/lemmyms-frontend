## Context

See `proposal.md` for the failure. The community directory has no sort control, so it should use a stable, supported default rather than a value chosen for post listings.

## Goals / Non-Goals

**Goals:**
- Send a community sort accepted by `CommunitySortType`.
- Keep the current listing type and cursor behavior.
- Cover the query and the rendered directory in both mock and real-backend tests.

**Non-Goals:**
- Adding a community sort selector.
- Changing post or comment sorting.
- Changing backend sort enums.

## Decisions

Use `active_monthly`, the backend default for `CommunitySortType`. Omitting `sort` would produce the same result, but an explicit value makes the contract visible in the request and in tests. `hot` and `subscribers` were considered; both change the directory's presentation without a matching UI control.

The mock browser test should inspect the actual `/api/v4/community/list` request instead of only returning fixtures. The real-backend test should open `/communities` after creating a community, which is the path that exposed the bug.

## Risks / Trade-offs

- The backend default could change later. The mock test should assert that the value belongs to the supported set, not only that it equals `active_monthly`.
- A real-backend directory can be rate-limited or empty after a failure. The assertion should use the community just created by the same test.
