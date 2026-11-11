## Why

The drawer already shows the signed-in identity at its top, but that block is static and the account list carries a separate "Profile" item. Making the existing identity header the profile entry removes the duplicate destination without adding another control to the application bar. Separately, profile links and person lookups mostly use `person.name`, which works for local accounts but drops the domain for remote authors. The v4 backend expects a local username for local accounts and `name@domain` for remote accounts.

## What Changes

- Remove the separate "Profile" destination from the drawer account list.
- Make the signed-in drawer identity header a link to the reader's own profile. It keeps the avatar, display name, username, and role text.
- Do not add a profile control to the application bar.
- Keep the anonymous drawer identity header linked to login.
- Add one shared profile-handle rule: local people use their single username, remote people use `name@domain`.
- Use that handle for author links, moderator links, search person links, profile routes, person reads, and person-content reads.
- Detect the signed-in reader's own profile by matching either the local username or the full local `name@domain` form.
- Normalize administrator ban inputs so a local actor URL becomes the single username and a remote actor URL becomes `name@domain`.
- Keep the existing `/u/:username` route shape; the path segment may contain either accepted handle form.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: profile entry placement and local-versus-remote profile handle behavior.
- `accessible-material-interface`: the drawer identity header becomes the profile link with an accessible name and target size, and the account list no longer includes a Profile destination.
- `lemmy-api-integration`: person and person-content lookup parameters use the correct local username or remote `name@domain` handle.

## Impact

- Frontend modules: `src/App/Shell.elm`, `src/App/Features.elm`, `src/App/Routing.elm`, `src/Lemmy/Domain.elm`, `src/Ui/PostCard.elm`, `src/Ui/CommentCard.elm`, `src/Feature/Community.elm`, `src/Feature/Profile.elm`, `src/App/View/Content.elm`, `src/Feature/SiteAdmin/Update.elm`, and `src/style.css`.
- Presentation: clickable drawer identity header, hover and focus treatment, and drawer account-list cleanup.
- Tests: drawer header routing, modal drawer closure, absence of a top-bar profile control, local and remote profile links, own-profile detection, local and remote person API queries, and ban actor normalization.
- Backend: no change. `GET /person?username=` and `GET /person/content?username=` already accept a local username or a remote `name@domain`.
