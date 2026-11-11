# Backend integration

The frontend targets `LemmyMultisite` `1.0.0-beta.3`. Reads and writes use the same-origin `/api/v4` API. Login remains a temporary exception: it posts to `/api/v3/user/login` only to establish the HttpOnly `jwt` cookie, then verifies the session with `GET /api/v4/account`. The v4 login route returns a JSON JWT without `Set-Cookie`, so switching to it before the backend sets the cookie would break cookie authentication. The v3 response body is not used.

The browser never reads the JWT. The cookie is host-scoped, `HttpOnly`, `SameSite=Lax`, and `Secure` when the request is HTTPS. There is no CSRF header. Requests are same-origin so the browser sends the cookie automatically.

The main request groups are:

| Area | Endpoints |
| --- | --- |
| Session | `GET /api/v4/site`, `GET /api/v4/account`, `POST /api/v3/user/login`, `POST /api/v4/account/auth/logout` |
| Registration and recovery | `POST /api/v4/account/auth/register`, `verify_email`, `resend_verification_email`, `password_reset`, `password_change`, `PUT /change_password` |
| Community | `GET/PUT /api/v4/community`, `POST /api/v4/community`, `GET /community/list`, `POST /community/follow`, `pending_follows/list`, `pending_follows/approve` |
| Posts | `GET/PUT/DELETE /api/v4/post`, `POST /api/v4/post`, `GET /post/list`, `POST /post/like`, `PUT /post/save`, `POST /post/mark_as_read`, `POST /post/hide`, `POST /post/report`, `PUT /post/report/resolve`, `POST /post/remove` |
| Comments | `GET/PUT/DELETE /api/v4/comment`, `POST /api/v4/comment`, `GET /comment?id=`, `GET /comment/list`, `POST /comment/like`, `PUT /comment/save`, `POST /comment/report`, `PUT /comment/report/resolve` |
| Search and mentions | `GET /api/v4/search` with `search_term`, `type_`, and `page_cursor` |
| Notifications | `GET /account/notification/list`, `GET /account/unread_counts`, `POST /account/notification/mark_as_read`, `POST /account/notification/mark_as_read/all` |
| Profiles | `GET /api/v4/person`, `GET /api/v4/account`, `PUT /account/settings/save`, `POST/DELETE /account/avatar` |
| Media | `POST/DELETE /api/v4/image`; avatars use `/account/avatar` |
| Account content | `GET /api/v4/account/saved`, `/read`, `/hidden`, `/liked`, `POST /api/v4/account/block/person`, `/community`, `/instance/persons`, `/instance/communities` |
| Community management | `GET/PUT /api/v4/community`, `/community/pending_follows/list`, `/community/pending_follows/approve`, `/community/mod`, `/community/ban_user`, `/report/list`, `/modlog` |
| Site administration | `GET/PUT /api/v4/site`, `/report/list`, `/modlog`, `/admin/ban` |

List responses use `items`, `next_page`, and `prev_page`. The client keeps the cursor returned by the same endpoint and does not derive offsets or totals. Community reads use `GET /community?name=`; listings and management mutations then use the returned numeric identifier. Comment permalinks use `GET /comment?id=` to find the containing post before loading the discussion. Post and comment bodies are Markdown and are rendered in Elm through an allowlisted renderer. Images upload through the v4 Pictrs endpoint and use the returned `image_url` and `filename`.

Management routes stay scoped to the tenant resolved by the browser Host. Community member rosters, submission review, removal queues, context backfill, and person reports have no v4 endpoint and are not implemented. The migration does not simulate those workflows.
