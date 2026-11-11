## Context

The drawer contains a Profile link in `drawerAccount`, while `viewTopBar` currently exposes only the menu button and wordmark. Person links and lookups mostly use `person.name`, even for remote people. The v4 person resolver treats an identifier containing `@` as remote and a bare identifier as local. See `proposal.md` for motivation.

## Goals / Non-Goals

**Goals:**

- Move profile navigation into the application bar.
- Use one handle rule for links and API reads.
- Keep local usernames free of the local hostname.
- Keep `/u/:username` compatible with both handle forms.

**Non-Goals:**

- Changing the person API contract.
- Adding a separate profile menu or hover card.
- Reworking the drawer identity header into a second navigation entry.

## Decisions

### Top-bar profile control

`viewTopBar` gains a right-side profile link when the session is authenticated. It shows the avatar always and the display name on wide screens. It links to `/u/<handle>` for the signed-in person. The drawer Profile destination is removed from `drawerAccount`; the drawer profile header remains a non-navigation identity summary.

The application bar keeps its menu button and wordmark. The profile control uses the localized profile label as its accessible name, so hiding the visible display name on compact widths does not remove the control name.

### Profile handle rule

`Domain.profileHandle : Person -> String` returns `person.name` when `person.local` is true and `Domain.acctOf person` otherwise. Author links, moderator links, search person links, and profile API reads use this helper. The existing `acctOf` remains the full `name@domain` builder for remote people.

The profile route still accepts any string segment. `Profile.loadPublic` sends the route handle unchanged to `/person?username=` and `/person/content?username=`. Own-profile detection accepts either `Domain.personName account` or `Domain.acctOf account.localUserView.person`; a local user does not need to enter the hostname, and an explicit local `name@host` still resolves as own.

### Ban actor normalization

`actorToUsername` keeps accepting a bare handle. For an actor URL, it extracts the trailing actor segment and host. If the host equals the current site hostname, it returns only the actor name; otherwise it returns `name@host`. This matches the person resolver's local and remote branches.

### Route behavior

No route shape changes. `/u/:username` continues to use a single path segment. `@` is legal after URL decoding, so a remote handle remains one segment. Local profile links continue to use the single name.

## Risks / Trade-offs

- **A remote profile may be uncached and fail anonymously** → Show the localized unavailable state; do not silently rewrite the handle to a local name.
- **The top bar can get crowded on narrow screens** → Hide the display name first, keep the avatar and accessible label, and preserve the menu and wordmark.
- **Own-profile comparison can drift** → Centralize local-name and local-acct matching in one domain helper and test both forms.
- **Ban actor URLs can target another instance** → Preserve the host in the normalized handle instead of assuming local.

## Migration Plan

1. Add the handle and own-profile helpers with unit tests.
2. Add the top-bar profile control and remove the drawer Profile link.
3. Replace profile link and person query call sites.
4. Normalize local and remote ban actor URLs.
5. Update accessibility, route, browser, and real-backend tests.
6. Roll back by reverting the change commit. No backend or data migration is involved.
