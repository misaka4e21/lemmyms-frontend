## Context

The drawer already renders the signed-in identity through `viewDrawerProfile`, but that block is a static `div`; `drawerAccount` also carries a separate Profile link. Person links and lookups mostly use `person.name`, even for remote people. The v4 person resolver treats an identifier containing `@` as remote and a bare identifier as local. See `proposal.md` for motivation.

## Goals / Non-Goals

**Goals:**

- Make the drawer identity header the profile entry.
- Remove the duplicate Profile destination from the drawer account list.
- Use one handle rule for links and API reads.
- Keep local usernames free of the local hostname.
- Keep `/u/:username` compatible with both handle forms.

**Non-Goals:**

- Changing the person API contract.
- Adding a profile control to the application bar.
- Adding a separate profile menu or hover card.
- Changing the anonymous drawer header's login behavior.

## Decisions

### Drawer identity header

`viewDrawerProfile` returns a link for authenticated readers, pointing to `/u/<handle>` for the signed-in person. The link wraps the existing avatar, display name, username, and role text, so the identity block does not gain a second profile control. `drawerAccount` drops the Profile destination. The anonymous branch keeps its existing login link.

The authenticated link uses a localized accessible name that names the profile and includes the displayed identity. The link receives the drawer's extra attributes so the modal drawer closes when the profile route opens. `viewTopBar` keeps its menu button and wordmark and gains no profile control.

### Profile handle rule

`Domain.profileHandle : Person -> String` returns `person.name` when `person.local` is true and `Domain.acctOf person` otherwise. Author links, moderator links, search person links, and profile API reads use this helper. The existing `acctOf` remains the full `name@domain` builder for remote people.

The profile route still accepts any string segment. `Profile.loadPublic` sends the route handle unchanged to `/person?username=` and `/person/content?username=`. Own-profile detection accepts either `Domain.personName account` or `Domain.acctOf account.localUserView.person`; a local user does not need to enter the hostname, and an explicit local `name@host` still resolves as own.

### Ban actor normalization

`actorToUsername` keeps accepting a bare handle. For an actor URL, it extracts the trailing actor segment and host. If the host equals the current site hostname, it returns only the actor name; otherwise it returns `name@host`. This matches the person resolver's local and remote branches.

### Route behavior

No route shape changes. `/u/:username` continues to use a single path segment. `@` is legal after URL decoding, so a remote handle remains one segment. Local profile links continue to use the single name.

## Risks / Trade-offs

- **A remote profile may be uncached and fail anonymously** → Show the localized unavailable state; do not silently rewrite the handle to a local name.
- **The identity header can still look static** → Give the whole header a hover and focus-visible treatment and keep its target at least 48 CSS pixels tall.
- **The modal drawer can stay open after navigation** → Pass the drawer's close attributes to the header link and test the closed state after activation.
- **Own-profile comparison can drift** → Centralize local-name and local-acct matching in one domain helper and test both forms.
- **Ban actor URLs can target another instance** → Preserve the host in the normalized handle instead of assuming local.

## Migration Plan

1. Add the handle and own-profile helpers with unit tests.
2. Make the drawer identity header a profile link, close the modal drawer on activation, and remove the separate Profile destination.
3. Replace profile link and person query call sites.
4. Normalize local and remote ban actor URLs.
5. Update accessibility, route, browser, and real-backend tests.
6. Roll back by reverting the change commit. No backend or data migration is involved.
