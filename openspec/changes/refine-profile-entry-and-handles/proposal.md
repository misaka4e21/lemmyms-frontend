## Why

The navigation drawer currently carries a dedicated "Profile" item even though the drawer already shows the signed-in identity at its top. The profile entry should move to the top bar so the drawer keeps a single account-navigation list. Separately, profile links and person lookups mostly use `person.name`, which works for local accounts but drops the domain for remote authors. The v4 backend expects a local username for local accounts and `name@domain` for remote accounts.

## What Changes

- Remove the "Profile" destination from the drawer account list.
- Add a profile button to the application bar. It shows the signed-in avatar and display name on wide screens, avatar only on compact screens, and links to the reader's own profile.
- Keep the drawer identity header as a display summary; it is no longer the profile navigation entry.
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
- `accessible-material-interface`: the navigation drawer account list no longer includes a Profile destination; the top-bar profile control has its own accessible name and target size.
- `lemmy-api-integration`: person and person-content lookup parameters use the correct local username or remote `name@domain` handle.

## Impact

- Frontend modules: `src/App/Shell.elm`, `src/App/View/Account.elm`, `src/App/Routing.elm`, `src/Lemmy/Domain.elm`, `src/Ui/PostCard.elm`, `src/Ui/CommentCard.elm`, `src/Feature/Community.elm`, `src/Feature/Profile.elm`, `src/Feature/Search.elm`, and `src/Feature/SiteAdmin/Update.elm`.
- Presentation: top-bar profile button, responsive avatar and name, drawer account-list cleanup.
- Tests: route construction and decoding, local and remote profile links, own-profile detection, local/remote person API queries, and the top-bar profile control.
- Backend: no change. `GET /person?username=` and `GET /person/content?username=` already accept a local username or a remote `name@domain`.
