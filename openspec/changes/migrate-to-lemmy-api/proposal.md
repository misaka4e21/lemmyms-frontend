## Why

The frontend currently targets Commune's site-scoped `/api/v1` contract, but the deployment target is `LemmyMultisite` `1.0.0-beta.3`, whose v4 API has a different authentication, data, pagination, and content model. The application cannot run against the target backend without replacing that contract.

## What Changes

- Replace the Commune transport layer with the Lemmy v4 API at `/api/v4`, keeping same-origin requests and removing the CSRF header path.
- Authenticate through an HttpOnly `jwt` cookie. The backend login response sets the cookie; the browser never reads or stores the token, and logout removes it.
- Replace the Commune DTOs with Lemmy v4 DTOs: `GetSiteResponse`, `MyUserInfo`, `PostView`, `CommentView`, `CommunityView`, `PersonView`, notification views, reports, and moderation records.
- Adopt Lemmy canonical URLs for existing features: `/post/:post_id/:comment_id?`, `/comment/:comment_id`, `/c/:name`, `/u/:username`, `/create_post`, `/create_community`, `/c/:name/settings`, `/admin`, `/reports`, `/modlog/:communityId?`, `/search`, `/settings`, `/notifications`, `/verify_email/:token`, and `/password_change/:token`.
- Replace offset pagination with the v4 `page_cursor`/`next_page` contract and expose the existing lists through cursor navigation.
- Rebuild the reply tree from `Comment.path` instead of the former recursive `children` fields.
- Map votes to `is_upvote: true|false|null`, and derive saved, read, hidden, follow, block, and vote state from `post_actions`, `comment_actions`, and `community_actions`.
- Render post bodies, comments, biographies, and community sidebars as sanitized Markdown in Elm. Add an Elm Markdown dependency and keep the existing allowlist policy for links, images, and embedded HTML.
- Replace `/api/v1/media` multipart uploads with the v4 Pictrs image upload contract and use the returned `image_url` and `filename`.
- **BREAKING**: drop the old `/api/v1` transport, CSRF bootstrap, Commune `permissions` fields, `body_html`, and the old route shapes. No runtime switch to the old backend remains.
- **BREAKING**: require the backend to set and clear the HttpOnly `jwt` cookie on login/logout, and require the deployment to proxy `/api/v4` and Pictrs on the frontend origin.

This change migrates only the features that already exist: discovery, community directory and detail, posts and threaded comments, authoring and editing, votes/save/read/hide, search, profiles, notifications, account collections and blocks, community management, site administration, reports, moderation history, bans, and password flows. Private messages, multi-community, federation instance browsing, tags, custom emoji, badges, OAuth, TOTP, registration applications, media administration, and the broader Lemmy user-settings surface are separate changes.

The v4 API has no endpoint for a community member roster, submission review, removal queues, context backfill, or person reports. Those Commune-only controls are removed from this migration and recorded as backend-dependent follow-ups rather than simulated.

## Capabilities

### New Capabilities
- `lemmy-api-integration`: same-origin v4 transport, HttpOnly JWT session, DTO decoding, cursor pagination, error mapping, and Lemmy-specific media and Markdown boundaries.

### Modified Capabilities
- `forum-application`: existing discovery, discussion, authoring, interaction, profile, notification, account, management, and moderation behavior now reads and writes the Lemmy v4 model and canonical URLs.
- `markdown-authoring`: the existing authoring surface now renders Lemmy Markdown source in Elm instead of consuming server-generated HTML, while preserving sanitization and accessibility behavior.
- `site-administration`: current-site settings, reports, moderation history, and bans now map to Lemmy site administration instead of Commune's site-vote and deployment-admin contracts.
- `localized-interface`: verification and password-reset tokens move to Lemmy path segments, and Lemmy error codes become localized interface outcomes.

## Impact

- Frontend modules: `src/Api.elm`, `src/Domain.elm`, `src/Route.elm`, `src/Main.elm`, `src/Ports.elm`, `src/bootstrap.js`, `src/App/*`, every `src/Feature/*` module, `src/Ui/PostCard.elm`, `src/Ui/Rich.elm`, and the shared layout modules.
- Backend: `LemmyMultisite` must set `Set-Cookie` for `jwt` with `HttpOnly`, `SameSite=Lax`, `Secure` when HTTPS, and `Path=/` on successful login, and must clear it on logout while keeping the JSON `jwt` field for other clients.
- Deployment: `vite.config.js`, `deploy/nginx.conf`, and browser tests move from `/api/v1` to `/api/v4`, with Pictrs and media routed on the same origin.
- Dependencies: add an Elm Markdown parser/renderer compatible with Elm 0.19.1; keep `hecrj/html-parser` for sanitized allowlist rendering of any embedded HTML.
- Tests and docs: domain decoders, route tests, browser tests, the real-backend acceptance fixture, `docs/backend-integration.md`, `docs/architecture.md`, and the forum-application/site-administration specs change with the new contract.
