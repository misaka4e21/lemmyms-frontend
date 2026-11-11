## Why

The v4 migration added `Lemmy.Route`, but the running application still imports the former Commune route module. Canonical links such as `/c/:name`, `/u/:username`, `/comment/:id`, `/reports`, and `/modlog/:id?` either fail to parse or render without data. Verification and reset links are rewritten by the bootstrap before the application can use their path tokens, and `/settings` is not a route. The shipped URLs do not match the v4 contract used by the specs and by lemmy-ui.

## What Changes

- Replace `src/Route.elm` with an extended `src/Lemmy/Route.elm` as the only application route module.
- Adopt the canonical Lemmy paths for existing features: `/`, `/communities`, `/c/:name`, `/c/:name/settings`, `/post/:post_id/:comment_id?`, `/comment/:comment_id`, `/create_post`, `/create_community`, `/u/:username`, `/search`, `/notifications`, `/settings`, `/admin`, `/reports`, `/modlog/:community_id?`, `/login`, `/signup`, `/verify_email/:token`, `/password_change/:token`, and `/login_reset`.
- Keep application-specific account, password, admin, and comment-edit routes where they do not conflict with a canonical path. Generate canonical paths for Lemmy destinations and accept the existing app-specific aliases.
- **BREAKING**: stop accepting the former Commune shapes `/communities/:id`, `/posts/:id`, `/posts/:id/edit`, `/profiles/:name`, `/register`, `/verify-email`, `/reset-password`, and `/reset-password/confirm`.
- Load `/c/:name` and `/c/:name/settings` by community name, then use the returned integer ID for post listings and management mutations.
- Resolve `/comment/:id` to its containing post, replace the history entry with `/post/:post_id/:comment_id`, and focus the referenced comment after the discussion loads.
- Read verification and reset tokens from their path segments in the application. Remove the bootstrap rewrites and the verification-token flag.
- Keep the temporary `/api/v3/user/login` cookie bridge. The v4 login handler returns a JSON JWT without `Set-Cookie`, so switching the endpoint would break the HttpOnly session. The backend dependency is documented instead of changed here.
- Remove the person-report control. The v4 API has no person-report endpoint, and the current submission path is a no-op.
- Start sort and depth changes from a fresh comment cursor. Remove the offset parameter from the comment route builder.
- Update route tests, browser tests, the real-backend acceptance links, and the architecture and backend-integration documentation.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: canonical route ownership, name-based community routes, comment permalink resolution, legacy route removal, and the account settings route.
- `accessible-material-interface`: focus and announcement behavior for a direct comment target.

## Impact

- Frontend modules: `src/Main.elm`, `src/Route.elm`, `src/Lemmy/Route.elm`, `src/App/Routing.elm`, `src/App/View.elm`, `src/App/View/Content.elm`, `src/App/View/Account.elm`, `src/App/Init.elm`, `src/bootstrap.js`, `src/Feature/Community.elm`, `src/Feature/CommunityManage/*`, `src/Feature/Post.elm`, `src/Feature/Profile.elm`, `src/Feature/Report.elm`, and `src/Feature/Auth/*`.
- Routes: canonical Lemmy paths replace the former Commune paths; existing app-specific account, admin, and password routes remain as aliases where they do not conflict.
- Tests: `tests/RouteTest.elm`, `tests/LemmyRouteTest.elm`, `tests-browser/forum.spec.js`, and `tests-browser/real-backend.spec.js`.
- Documentation: `docs/architecture.md`, `docs/backend-integration.md`, and the acceptance notes that reference route shapes.
- Backend: no change. The v3 login bridge remains until the v4 login route sets the HttpOnly cookie.
