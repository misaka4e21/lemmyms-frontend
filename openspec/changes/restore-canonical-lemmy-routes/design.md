## Context

See `proposal.md` for motivation. The current application has two route modules with overlapping responsibilities. `src/Route.elm` owns the routes that `Main`, `App.Routing`, and every view import. `src/Lemmy/Route.elm` already parses the canonical v4 paths but is referenced only by `tests/LemmyRouteTest.elm`. The v4 API accepts community names for reads and integer community IDs for listings and mutations, so a name-based route needs a load step before it can issue ID-based requests. The v4 login handler returns a JSON JWT without `Set-Cookie`; only the v3 handler establishes the HttpOnly session cookie.

## Goals / Non-Goals

**Goals:**

- Make the canonical Lemmy paths the routes the application generates and serves.
- Keep every existing account, administration, and authoring workflow reachable.
- Resolve comment permalinks to a visible comment in its discussion.
- Read verification and reset tokens from their path segments.
- Remove the dead person-report control and the unsupported Commune route shapes.

**Non-Goals:**

- Changing the login endpoint or backend cookie behavior.
- Adding new browsing, moderation, messaging, or settings features.
- Keeping redirects for the former Commune paths.

## Decisions

### One route module

Extend `src/Lemmy/Route.elm` with the application-specific routes that the canonical set does not cover, then delete `src/Route.elm`. The application-specific additions are `/account/saved`, `/account/read`, `/account/hidden`, `/account/liked`, `/account/blocks`, `/settings/password`, `/admin/reports`, `/admin/modlog`, `/admin/bans`, `/admin/settings`, and `/comment/:id/edit`.

Keeping two route modules would leave two path builders and two parsers to keep in sync. The canonical routes already exist in `Lemmy.Route`; extending that module is smaller than duplicating its table in the old module.

| Destination | Generated path | Accepted aliases |
| --- | --- | --- |
| Latest | `/` | none |
| Communities | `/communities` | none |
| Community | `/c/:name` | none |
| Community settings | `/c/:name/settings` | none |
| Post | `/post/:postId/:commentId?` | none |
| Comment resolver | `/comment/:commentId` | none |
| Comment editor | `/comment/:commentId/edit` | none |
| Create post | `/create_post?community_id=:id` | `/create_post` |
| Edit post | `/create_post?post_id=:id` | none |
| Create community | `/create_community` | none |
| Profile | `/u/:username` | none |
| Search | `/search` | none |
| Notifications | `/notifications` | none |
| Settings | `/settings` | `/settings/profile` |
| Password settings | `/settings/password` | none |
| Account collections | `/account/saved`, `/account/read`, `/account/hidden`, `/account/liked` | none |
| Blocks | `/account/blocks` | none |
| Administration | `/admin` | none |
| Reports | `/reports` | `/admin/reports` |
| Modlog | `/modlog/:communityId?` | `/admin/modlog` |
| Bans | `/admin/bans` | none |
| Site settings | `/admin/settings` | none |
| Login | `/login` | none |
| Registration | `/signup` | none |
| Email verification | `/verify_email/:token` | none |
| Password change | `/password_change/:token` | none |
| Login reset | `/login_reset` | none |

The old `/communities/:id`, `/posts/:id`, `/posts/:id/edit`, `/profiles/:name`, `/register`, `/verify-email`, `/reset-password`, and `/reset-password/confirm` paths become `NotFound`. Redirects would require fetching a community by ID before the name is known and would preserve two URL shapes after the migration declared the old shapes breaking.

### Community routes use names

`Community` and `CommunitySettings` carry the community name. `Feature.Community` first reads `/community?name=:name`, then requests the post list with the returned `community.id`. `Feature.CommunityManage` reads the same name, stores the loaded `CommunityView`, and derives the integer ID for follow decisions, moderator changes, bans, and report resolution from that value.

The alternative, keeping the numeric ID in the URL and adding the name as a query parameter, would not produce portable links and would leave the canonical route unused. The extra read adds one request to community entry; the route epoch still discards a stale community or topic response after navigation.

### Comment permalinks resolve to the post route

`/comment/:commentId` is a resolver, not a second discussion renderer. The application reads `/comment?id=:commentId`, obtains the containing post ID, and calls `Navigation.replaceUrl` with `/post/:postId/:commentId`. The post route then loads the post and replies. The optional comment segment is passed to the discussion view as the focus target.

Rendering the discussion under both `/comment/:commentId` and `/post/:postId/:commentId` would duplicate loader state and produce two URLs for one discussion. `replaceUrl` keeps Back navigation working because the comment route is replaced rather than added to history.

### Tokens come from the route

`App.Init` derives the verification or reset token from the parsed route and passes it to `Feature.Auth.State`. `src/bootstrap.js` stops rewriting `/verify_email/:token` and `/password_change/:token`, and the `verificationToken` flag is removed. After a token is consumed or rejected, the existing history replacement moves the reader to a token-free route.

Keeping the bootstrap rewrite would leave the application parsing a different URL than the browser received, which contradicts the path-token requirement and hides invalid paths from the route tests.

### Login stays on the v3 cookie bridge

The application continues to call `/api/v3/user/login` to establish the HttpOnly `jwt` cookie, then verifies the session through `/api/v4/account`. The v4 login route returns the JWT in JSON and does not set a cookie. Switching to it without a backend change would break cookie authentication and expose the token to the application.

This is a recorded backend dependency. It is not part of this change and does not alter the v4 API boundary.

### Person reporting is removed

The profile page stops rendering the report-person control, and `Report.PersonTarget`, its message handling, and its no-op submission branch are removed. The v4 API has no person-report endpoint, and the existing control cannot produce a request.

### Sort and depth changes reset the comment cursor

`SortChanged` and `DepthChanged` build a comment URL without `page_cursor` and without the old `offset` parameter. The cursor belongs to one sort and depth sequence; carrying it across a sort change would request a page from the wrong sequence.

## Risks / Trade-offs

- **Old bookmarks stop working** → The migration already declared the Commune route shapes breaking. The proposal and docs list the removed paths, and the not-found page remains available.
- **Community entry makes two requests** → Load the community first, show its loading state, then request topics. Route epochs prevent a late response from replacing a newer page.
- **Management actions need a loaded community ID** → Centralize the ID lookup in management state and disable mutations until the community is ready.
- **Comment resolution adds a request and a redirect** → Replace the history entry before loading the discussion. Treat missing, forbidden, or deleted comments as a localized unavailable state.
- **Token handling moves out of the bootstrap** → Test both token routes through direct browser loads and verify that the token is absent from the address after completion.
- **The v3 login bridge remains** → Document the missing v4 `Set-Cookie` contract in `docs/backend-integration.md`. Do not add a frontend fallback that stores the JWT.

## Migration Plan

1. Extend `Lemmy.Route`, add route tests, and switch imports.
2. Update route loaders and views for name-based communities, comment resolution, settings, and administration aliases.
3. Remove the bootstrap rewrites and the verification-token flag; derive tokens from the parsed route.
4. Remove the person-report control and its dead submission path.
5. Update browser tests, real-backend acceptance URLs, and documentation.
6. Roll back by reverting the change commit. No persisted data or backend state changes.
