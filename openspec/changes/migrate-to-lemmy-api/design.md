## Context

See `proposal.md` for motivation. The current Elm application is a `Browser.application` with feature-owned state, a shared `Api` transport, a `Domain` decoder module, and route epochs that discard stale responses. It assumes a same-origin Commune backend with a session cookie, a CSRF header, string identifiers, a combined post/reply DTO, server-rendered `body_html`, and offset pagination.

The target is `LemmyMultisite` `1.0.0-beta.3`. Its v4 routes are mounted at `/api/v4`, its JSON responses are plain DTOs, and errors are `{ "error": "...", "message": ... }`. Authentication accepts either `Authorization: Bearer` or a `jwt` cookie. The current login handler returns the JWT only in JSON; logout already removes a `jwt` cookie. The installation serves multiple sites by request host, so cookies must remain host-scoped.

## Goals / Non-Goals

**Goals:**

- Replace the transport, domain decoding, and route surface for the features already implemented.
- Keep the existing Elm feature composition, accessibility behavior, localization catalogs, and presentation design.
- Make the browser session HttpOnly and same-origin, with no JWT in JavaScript-readable storage.
- Render Lemmy Markdown safely in Elm and preserve the existing allowlist behavior.
- Use cursor pagination and Lemmy sorting/listing values without inventing totals or page numbers.

**Non-Goals:**

- Private messages, multi-community, federation instance browsing, tags, custom emoji, badges, OAuth, TOTP, registration applications, media administration, and the broader user-settings surface.
- Deployment-wide administration across tenants.
- Preserving Commune-only management concepts that have no v4 endpoint: member rosters, submission review, removal queues, context backfill, and person reports.
- A runtime switch between the old and new backends.

## Decisions

### Same-origin v4 proxy, cookie authentication

The browser will call `/api/v4/*` on the frontend origin. Vite will proxy that prefix during development, and nginx will proxy it in production. This keeps cookies first-party, avoids CORS, and lets the browser send the HttpOnly cookie automatically. `Api.get` and `Api.send` will stop adding `X-CSRF-Token`; `Api.send` will keep JSON bodies and `Api.upload` will target the v4 image endpoint.

Alternative considered: point the client at a separate `LEMMY_UI_BACKEND` origin. Rejected because it requires credentialed CORS, reintroduces cross-site cookie behavior, and complicates the multisite host model.

The migrated surface maps to these v4 paths:

| Area | Paths |
| --- | --- |
| Session and site | `GET /api/v4/site`, `GET /api/v4/account`, `POST /api/v4/account/auth/login`, `POST /api/v4/account/auth/logout` |
| Registration and recovery | `POST /api/v4/account/auth/register`, `POST /api/v4/account/auth/verify_email`, `POST /api/v4/account/auth/resend_verification_email`, `POST /api/v4/account/auth/password_reset`, `POST /api/v4/account/auth/password_change`, `PUT /api/v4/account/auth/change_password` |
| Community | `GET/PUT /api/v4/community`, `POST /api/v4/community`, `GET /api/v4/community/list`, `POST /api/v4/community/follow`, `POST /api/v4/community/report`, `PUT /api/v4/community/report/resolve`, `POST /api/v4/community/ban_user`, `POST /api/v4/community/mod`, `POST /api/v4/community/transfer`, `GET /api/v4/community/pending_follows/list`, `POST /api/v4/community/pending_follows/approve` |
| Post | `GET/PUT/DELETE /api/v4/post`, `POST /api/v4/post`, `GET /api/v4/post/list`, `POST /api/v4/post/like`, `PUT /api/v4/post/save`, `POST /api/v4/post/mark_as_read`, `POST /api/v4/post/hide`, `POST /api/v4/post/report`, `PUT /api/v4/post/report/resolve` |
| Comment | `GET/PUT/DELETE /api/v4/comment`, `POST /api/v4/comment`, `GET /api/v4/comment/list`, `POST /api/v4/comment/like`, `PUT /api/v4/comment/save`, `POST /api/v4/comment/report`, `PUT /api/v4/comment/report/resolve` |
| Search and person | `GET /api/v4/search`, `GET /api/v4/person` |
| Account | `GET /api/v4/account/saved`, `GET /api/v4/account/read`, `GET /api/v4/account/hidden`, `GET /api/v4/account/liked`, `PUT /api/v4/account/settings/save`, `POST/DELETE /api/v4/account/avatar`, `POST/DELETE /api/v4/account/banner`, `POST /api/v4/account/block/person`, `POST /api/v4/account/block/community`, `POST /api/v4/account/block/instance/persons`, `POST /api/v4/account/block/instance/communities` |
| Notifications | `GET /api/v4/account/notification/list`, `GET /api/v4/account/unread_counts`, `POST /api/v4/account/notification/mark_as_read`, `POST /api/v4/account/notification/mark_as_read/all` |
| Reports and moderation | `GET /api/v4/report/list`, `GET /api/v4/modlog`, `POST /api/v4/admin/ban`, `GET /api/v4/admin/users` |
| Media | `POST/DELETE /api/v4/image` |

### HttpOnly cookie set by the backend

The frontend cannot create an HttpOnly cookie. The login handler in `LemmyMultisite` will remain JSON-compatible but will also set `Set-Cookie: jwt=...; HttpOnly; SameSite=Lax; Path=/; Secure` when the request is HTTPS. It will omit the `Domain` attribute so the cookie stays host-only for each tenant. Logout already removes the cookie and invalidates the login token; the frontend will call it and then clear local session state.

The frontend will never read the JSON `jwt` field into its model, ports, storage, or URLs. `bootstrap.js` will lose the CSRF reader and the `csrf` flag. Session restoration will call `GET /api/v4/account`; a 401 means anonymous. The `GetSite` response does not contain `my_user`, so startup performs `GET /api/v4/site` and, when needed, `GET /api/v4/account`.

Alternatives considered: keep the `lemmy-ui` pattern of a JavaScript-readable `jwt` cookie and an `Authorization` header. Rejected because it exposes the token to XSS. Store the JWT in memory or `sessionStorage`. Rejected because the user selected an HttpOnly cookie and because either choice loses login across reloads or weakens the storage boundary.

CSRF: `SameSite=Lax` blocks cross-site POST/PUT/DELETE cookie sending. The backend should additionally validate the `Origin`/`Referer` host for cookie-authenticated mutations. This is a defense-in-depth requirement for the backend cookie change; the frontend will not invent a CSRF token that the v4 contract does not define.

### Replace the domain model rather than adapt it

`Domain` will be rebuilt around the v4 view types: `SiteView`, `MyUserInfo`, `PostView`, `CommentView`, `CommunityView`, `PersonView`, `NotificationView`, `ReportCombinedView`, and `ModlogView`. Posts and comments become separate types. IDs become `Int`; `ap_id`, `actor_id`, and other federation identifiers remain opaque strings. Display counts live on the post/comment/community records; viewer state comes from `post_actions`, `comment_actions`, `community_actions`, and `person_actions`.

Alternative considered: map `PostView` and `CommentView` back into the current combined `Post` and nested `ThreadedPost`. Rejected because the reply tree, edit/delete routes, permissions, and notification targets would keep diverging from the v4 model.

### Comment tree from `path`

The application will request comments for a post with `post_id`, `max_depth`, `sort`, and a cursor. It will build the visible tree from the dot-separated integer `path` and use `child_count` for the expand/collapse affordance. Root pagination remains server-driven. Orphaned or malformed path segments render at the root rather than dropping the comment.

Alternative considered: ask the backend for nested children. Rejected because v4 returns flat `CommentView` items and `path` is the authoritative tree location.

### Permission derivation

The frontend will compute authoring and moderation affordances from:

- `post.creator_id` or `comment.creator_id` versus `my_user.local_user_view.person.id`
- `post.can_mod` / `comment.can_mod` and `community.can_mod`
- `my_user.local_user_view.local_user.admin`
- `my_user.moderates` for community-scoped actions
- community `posting_restricted_to_mods` and `visibility`

The server remains authoritative; 403/404 responses still win. The removed Commune `permissions` object will not be simulated.

### Markdown rendering

Add a pure-Elm Markdown renderer compatible with Elm 0.19.1, planned as `dillonkearns/elm-markdown`, and render directly to `Html` with custom link and image renderers. Raw HTML will be disabled in the Markdown parser. Any HTML that must be displayed from legacy content will continue through `Ui.Rich` and its existing allowlist. The renderer will reject unsafe URL schemes and apply no-referrer/lazy behavior to images.

Alternative considered: keep consuming server HTML. Rejected because v4 returns Markdown source and has no `body_html` field. Alternative considered: render Markdown to an HTML string and re-parse it. Rejected as an unnecessary second trust boundary; direct typed rendering is simpler and safer.

### Canonical routes with query state

`Route.elm` will parse Lemmy canonical paths. Sort, listing type, and cursor values will be query parameters so they remain bookmarkable. Post detail supports an optional comment ID; a comment permalink uses `/comment/:comment_id`. The old `/posts/*`, `/communities/:id`, and `/profiles/:name` routes will not be redirected; this is a hard cutover.

Alternative considered: keep the old routes as aliases. Rejected because the user selected Lemmy canonical URLs and because aliases would keep two route models alive.

### Cursor state and stale responses

The existing route epoch and authentication generation remain. Cursor responses carry `next_page`/`prev_page`; the application stores the cursor used for the current view and the returned cursors, not an offset. A sort or filter change clears the cursor. Responses from a previous epoch or a previous cursor are discarded.

### Error model

`Api.Problem` will carry the HTTP status and the decoded `error` code, with optional `message` retained only for diagnostics. The UI maps known codes to localized catalog keys and unknown codes to a generic failure. Mutations are never retried automatically.

## Risks / Trade-offs

- **Cross-repository backend change**: login must set the HttpOnly cookie. Mitigation: keep the JSON `jwt` field for other clients, add the cookie additively, and test both header and cookie authentication against the real `LemmyMultisite` build.
- **Host-only cookie scope in a multisite installation**: a cookie with a parent `Domain` would leak sessions between tenants. Mitigation: omit `Domain`, use `Path=/`, and test two hosts on the same installation.
- **CSRF with cookie auth**: HttpOnly prevents token theft but not cross-site request sending. Mitigation: `SameSite=Lax` plus backend Origin validation; never expose state-changing operations over GET.
- **Markdown parser coverage**: the chosen Elm package may not implement every Lemmy Markdown extension. Mitigation: pin the package, add fixture coverage for the constructs used by existing content, and render unsupported constructs as text rather than raw HTML.
- **Loss of optimistic edit protection**: v4 has no `expected_version`. Mitigation: preserve the draft on failure, reload current source after conflict or success, and document that concurrent tabs are last-write-wins at the API layer.
- **Comment path edge cases**: deleted or filtered ancestors can leave gaps. Mitigation: render orphans at the root and do not reconstruct missing comments.
- **Cursor navigation and browser history**: cursors are opaque and can expire. Mitigation: treat an invalid cursor as an error with a link back to the first page; do not decode the cursor.
- **Scope gaps**: member rosters, submission review, removal queues, context backfill, and person reports have no v4 endpoint. Mitigation: remove those controls in this change and record them as separate backend-dependent items.
- **Multisite `GetSite` caching**: the backend caches the site response per local-site ID. Mitigation: rely on the `Host`/tenant middleware and test that two hosts receive their own site data.

## Migration Plan

1. Add a v4 contract fixture set from the running `LemmyMultisite` backend and make DTO decoders pass against it before changing UI behavior.
2. Add the backend HttpOnly cookie setting to login, keep logout cookie removal, and verify host-only scope on two tenant hosts.
3. Replace the transport and startup flow: `/api/v4`, cookie session, `GetSite` plus `GetMyUser`, no CSRF port, and the new error model.
4. Replace routes and the domain model, then migrate browsing, post/comment detail, authoring, voting, saving, reading, hiding, search, profiles, and notifications.
5. Migrate account collections, personal blocks, community management, reports, modlog, community bans, site administration, and password flows.
6. Remove the old `/api/v1` documentation, CSRF code, tests, and fixtures; update nginx/Vite and the real-backend acceptance harness.

Rollback: the backend cookie change is additive, so an older frontend that reads the JSON JWT can still authenticate. A frontend rollback alone is not sufficient because the old frontend still calls `/api/v1`; a full rollback redeploys the previous frontend and the previous backend version. No dual-backend runtime switch is provided.

## Open Questions

- The exact `dillonkearns/elm-markdown` version will be pinned during apply after checking the Elm package registry and the project's lock/cache behavior. This does not change the spec or task breakdown.
