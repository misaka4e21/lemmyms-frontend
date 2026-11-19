# Design

## Context

See proposal.md for the motivation and scope. The frontend currently renders administration destinations as links to separate routes. Its `/admin/users` screen calls the v4 admin list endpoint with `banned_only`, `sort`, `limit`, and cursor parameters, and exposes administrator assignment and username changes inline. In the backend, `AdminListUsers` has no search field; `/admin/users` checks the admin role and scopes the query to `tenant.local_site().id`. `LocalUserView` contains email and account state, so responses containing it must remain admin-only. The existing public person endpoint and profile route can remain unchanged.

## Goals / Non-Goals

**Goals:**

- Keep each administration section at its own URL while presenting shared tab navigation and selection state.
- Make username and email search server-side, tenant-scoped, and stable across cursor pagination.
- Separate public profile presentation from an administrator-only account detail view.
- Keep email and other local account fields out of public person responses.

**Non-Goals:**

- Add deployment-wide user search or cross-tenant administration.
- Add account operations beyond those already supported.
- Change the existing public profile route or its posts/comments and own-account collection tabs.

## Decisions

1. **Keep administration sections as separate routes.** Render a shared tab-style navigation whose selected item derives from the current route. Tabs remain ordinary links so direct loads, refreshes, and browser history keep working. A single in-page tab state was considered but conflicts with the requested independent URLs.

2. **Search on the backend using one query term.** Extend the admin user-list query with an optional term matched case-insensitively against local username and email, and apply it before pagination. Preserve existing sort and banned-only behavior. This avoids loading the full inventory or searching only the current page in the browser. Since email is private, this query remains behind the existing admin guard and current-tenant scope.

3. **Use a separate administrator detail route and response.** Add a person-ID detail destination under the admin user route and a backend read that requires a site administrator and resolves the user within the current tenant. The response may include local account fields needed by administrators; it must not be reused by the public profile page. Keep administrator assignment and username change on this detail surface and link to the existing public profile separately.

4. **Keep public profile data on the public person API.** Link to the existing public profile route for public person content. The administrator detail endpoint is separate and must not change public profile behavior or expose its private account fields through the public person response.

## Risks / Trade-offs

- [Email search can reveal sensitive account data] -> Keep the filter and returned email strictly behind admin authorization and current-tenant scoping; do not include email in public person responses.
- [Cursor pagination can produce inconsistent results if the search term is dropped] -> Preserve the query term and existing filters in every pagination link and request.
- [The admin detail view may become a catch-all for unsupported moderation actions] -> Limit controls to existing administrator assignment and username change.

## Migration Plan

Deploy the backend additions before or together with the frontend that calls them. Existing clients may continue using `/admin/users` without a search term and receive the current unfiltered list. If rollout must be reversed, remove the frontend search/detail controls first; the backend can retain the additive optional query and admin-only endpoint.
