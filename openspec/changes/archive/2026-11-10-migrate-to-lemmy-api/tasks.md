## 1. Contract and Backend Prerequisites

- [x] 1.1 Capture v4 response fixtures for site, account, community, post, comment, search, notification, report, modlog, and image upload; verify each fixture is committed under `tests/` and decodes without field guessing.
- [x] 1.2 Implement the temporary login bridge: post credentials to `/api/v3/user/login`, discard its response body, then verify the HttpOnly cookie with `GET /api/v4/account`; verify the browser never reads the JWT and that all non-login requests use `/api/v4`.
- [x] 1.3 Verify logout invalidates the login token and removes the `jwt` cookie, and verify two tenant hosts do not receive each other's cookie.
- [x] 1.4 Define the v4 error-code catalog and verify known codes, unknown codes, and validation/rate-limit responses decode into the shared problem type.

## 2. Transport and Session Core

- [x] 2.1 Replace the `/api/v1` transport with same-origin `/api/v4` requests that rely on the browser cookie; verify no request adds `X-CSRF-Token` and a `GET /api/v4/site` succeeds.
- [x] 2.2 Remove CSRF reads, ports, flags, and refresh calls from `bootstrap.js`, `Ports.elm`, and the startup flow; verify `rg -n "csrf|CSRF" src` finds no active session code.
- [x] 2.3 Load `GetSite` and `GetMyUser` at startup, derive anonymous/authenticated state from the account request, and verify anonymous and signed-in browser tests.
- [x] 2.4 Preserve route epochs and authentication generations, discard stale protected responses after logout, and verify a session-expiry browser test.
- [x] 2.5 Implement the v4 error model with status plus `error` code, map known codes to localized messages, and verify unknown-code fallback tests.

## 3. Domain Model and Routing

- [x] 3.1 Replace `Domain` with v4 `SiteView`, `MyUserInfo`, `PostView`, `CommentView`, `CommunityView`, `PersonView`, notification, report, modlog, and image types; verify fixture decoding tests cover optional and missing fields.
- [x] 3.2 Implement the `Comment.path` tree builder with `child_count`; verify unit tests for nested replies, orphans, and malformed paths.
- [x] 3.3 Implement cursor pagination state for post, comment, search, notification, report, modlog, and account lists; verify next/previous navigation and sort/filter reset tests.
- [x] 3.4 Replace the route parser and path builders with Lemmy canonical URLs, including optional comment IDs and query state; verify `RouteTest` covers direct loading and back/forward shapes.
- [x] 3.5 Implement permission derivation from `creator_id`, `can_mod`, `local_user.admin`, `my_user.moderates`, community visibility, and posting restrictions; verify role and ownership unit tests.

## 4. Markdown and Media

- [x] 4.1 Add the Elm Markdown dependency and pin its version; verify `ELM_HOME=/tmp/commune-elm-home npm run compile` resolves it.
- [x] 4.2 Implement sanitized Markdown rendering for post bodies, comments, biographies, community sidebars, and site text; verify tests reject unsafe schemes, raw HTML, and event-handler attributes.
- [x] 4.3 Replace the Commune multipart upload with the v4 Pictrs image endpoint; verify a successful upload inserts `image_url` and a malformed response preserves the editor text.
- [x] 4.4 Remove `body_html` rendering assumptions and verify no view reads the removed field.

## 5. Browsing, Search, Profiles, and Notifications

- [x] 5.1 Migrate the home and community post listings to `ListingType`, supported sorts, and cursor navigation; verify browser tests for sort changes and empty pages.
- [x] 5.2 Migrate post detail and comments to separate v4 DTOs and the path-built tree; verify deep-thread, collapse/expand, and comment permalink browser tests.
- [x] 5.3 Migrate search to `search_term`/`type_`/`listing_type` with post and community result variants; verify localized search browser tests.
- [x] 5.4 Migrate community directory and detail to `CommunityView`, follow state, subscriber counts, visibility, and posting restrictions; verify anonymous and private-community browser tests.
- [x] 5.5 Migrate public and own profiles, avatar/banner uploads, and Markdown biography editing; verify profile save and upload browser tests.
- [x] 5.6 Migrate notifications to `NotificationView`, unread counts, per-notification read, and mark-all-read; verify notification routing and unread-count browser tests.

## 6. Authoring and Interactions

- [x] 6.1 Migrate post creation and editing to `CreatePost`/`EditPost` with Markdown source and community selection; verify create, edit, and failed-edit draft preservation tests.
- [x] 6.2 Migrate comment creation, editing, and deletion to `CreateComment`/`EditComment`/`DeleteComment`; verify reply, edit, delete, and permission-revoked tests.
- [x] 6.3 Migrate votes to `is_upvote: true|false|null` and action-derived state; verify upvote, downvote, clear, switch, and disabled-direction tests.
- [x] 6.4 Migrate save, read, and hide actions to v4 post/comment action endpoints; verify each action and its refreshed state.
- [x] 6.5 Migrate post, comment, and community reporting to type-specific report endpoints; verify submit, self-report rejection, and validation tests.
- [x] 6.6 Replace mention candidates with v4 person search, preserving debounce, stale-response rejection, and IME behavior; verify candidate lookup and insertion tests.

## 7. Account Flows

- [x] 7.1 Migrate saved, read, hidden, and liked post collections to v4 account endpoints with cursors; verify each collection and empty/error state.
- [x] 7.2 Migrate personal person, community, and instance blocks to v4 block endpoints and IDs; verify add/remove and self-block rejection tests.
- [x] 7.3 Migrate login, logout, session restoration, and registration modes (`open`, `require_application`, `require_invitation`, `closed`); verify each mode and logout cookie behavior.
- [x] 7.4 Migrate email verification and password reset to `/verify_email/:token` and `/password_change/:token`, including history replacement; verify token capture and invalid-token tests.
- [x] 7.5 Migrate authenticated password change to `ChangePassword`; verify success, wrong-current-password, and field-clearing tests.

## 8. Community Management

- [x] 8.1 Migrate community creation and settings to `CreateCommunity`/`EditCommunity` fields: name, title, sidebar, summary, NSFW, visibility, posting restriction, languages, and vote modes; verify create and edit browser tests.
- [x] 8.2 Migrate moderator management to `AddModToCommunity` and `TransferCommunity`; verify add, remove, transfer, and self-action guards.
- [x] 8.3 Migrate follow approvals to `pending_follows` list and approve; verify pending, accepted, denied, and private-community tests.
- [x] 8.4 Migrate community bans to person-ID `BanFromCommunity` with reason and epoch expiry; verify ban, unban, expiry, and unresolved-actor tests.
- [x] 8.5 Migrate community-scoped reports and modlog to the unified report list and v4 modlog; verify filter, resolve, conflict, and read-only tests.
- [x] 8.6 Remove member roster, submission review, removal queue, and context backfill controls; verify no route or request remains and the backend-gap message is shown where needed.

## 9. Site Administration

- [x] 9.1 Gate `/admin`, `/reports`, and `/modlog` on `local_user.admin`; verify anonymous, non-admin, and admin access tests.
- [x] 9.2 Migrate site default vote modes to `EditSite` and verify the creation-default explanation, save, and failure tests.
- [x] 9.3 Migrate the unified report queue and type-specific resolutions; verify filter, resolve, reject, and conflict tests.
- [x] 9.4 Migrate the modlog view and its supported filters; verify cursor navigation and read-only presentation.
- [x] 9.5 Migrate person bans to actor resolution plus `BanPerson`, including reason and epoch expiry; verify resolved, unresolved, ban, and unban tests.
- [x] 9.6 Remove deployment-wide site/account/role/cross-tenant administration surfaces; verify only current-host management is reachable.

## 10. Deployment, Documentation, and Cleanup

- [x] 10.1 Route `/api/v4` and Pictrs through Vite and nginx on the frontend origin; verify development and production-preview browser tests.
- [x] 10.2 Update `docs/backend-integration.md`, `docs/architecture.md`, and deployment notes for v4, the HttpOnly cookie, canonical URLs, cursor pagination, Markdown, and Pictrs; verify the documented request paths and cookie behavior match the implemented client and deployment config.
- [x] 10.3 Remove the old `/api/v1`, CSRF, `body_html`, and Commune DTO code and tests; verify `rg -n "/api/v1|X-CSRF-Token|body_html" src tests docs` finds no active implementation.
- [x] 10.4 Update the real-backend acceptance fixture for a `LemmyMultisite` tenant, including login/logout cookie behavior, post/comment creation, votes, community management, reports, and modlog; verify the fixture passes against the running backend.
- [x] 10.5 Run `ELM_HOME=/tmp/commune-elm-home npm run compile`, `ELM_HOME=/tmp/commune-elm-home npm test`, `npm run i18n:check`, `npm run format:check`, and `npm run test:browser`; record any environment-only failures separately.
- [x] 10.6 Record the removed Commune-only workflows and the backend endpoints still needed for them in the change notes; verify the report distinguishes implemented migration from backend-dependent follow-ups.
