# Tasks

## 1. Backend user search and administrator detail API

- [ ] 1.1 Extend the current-tenant admin user-list query in `/data/xyh/code/rust/LemmyMultisite` with case-insensitive username/email partial search before pagination, preserving sort and banned-only filters; verify matching, no-match, pagination, and tenant isolation in API/database tests.
- [ ] 1.2 Add an admin-only user detail read scoped to the current tenant and returning the account fields required by the management view; verify anonymous/non-admin denial and rejection of a person outside the tenant in backend tests.
- [ ] 1.3 Keep the admin detail response and email field inaccessible through public person responses; verify response serialization and authorization in backend tests.

## 2. Administration navigation and user inventory

- [ ] 2.1 Render the shared site administration navigation as route-aware tabs while retaining each existing URL; verify direct route loads, selected-tab state, and keyboard navigation in frontend tests.
- [ ] 2.2 Add username/email search input to the site user inventory and send the term with the existing filters; preserve the term through cursor navigation and verify matching/empty-state behavior in frontend tests.
- [ ] 2.3 Link each inventory row to its administrator detail route and remove inline management controls from the inventory where those controls move to the detail view; verify links target the correct person and current tenant.

## 3. Public and administrator profile views

- [ ] 3.1 Keep the existing public profile route and public person data behavior unchanged; add a public-profile link from administrator detail without exposing local account fields, and verify it targets the selected person.
- [ ] 3.2 Add the administrator-only user detail route and render account information, administrator assignment, and username change using the admin detail response; verify access gating, successful updates, and retained drafts after failures.
- [ ] 3.3 Add or update translations for tab labels, user search, detail headings, and unavailable/forbidden states; verify every supported locale has a fallback or translation.

## 4. Integration

- [ ] 4.1 Run the relevant frontend and backend test suites and verify the complete workflow: search, paginate, open administrator detail, use the management actions, and open the selected user's public profile.
