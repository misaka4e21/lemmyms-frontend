## 1. Handle helpers

- [ ] 1.1 Add `Domain.profileHandle` for local versus remote people and an own-profile matcher for single-name and local-acct forms, and verify unit tests cover both.
- [ ] 1.2 Normalize administrator ban actor URLs by local host or remote host, and verify local URLs produce a bare name and remote URLs keep `name@domain`.

## 2. Profile entry

- [ ] 2.1 Add the authenticated top-bar profile control with avatar and responsive display name, and verify its route and accessible name.
- [ ] 2.2 Remove the drawer Profile destination while keeping the drawer identity header, and verify the authenticated account list order.

## 3. Handle call sites

- [ ] 3.1 Use the shared handle for post and comment author links, community moderator links, and search person links, and verify local and remote fixtures.
- [ ] 3.2 Use the shared handle unchanged in `/person` and `/person/content` reads, and verify local requests omit the hostname and remote requests retain it.
- [ ] 3.3 Treat both own local handle forms as the own profile and verify own tabs, including the explicit `name@host` route.

## 4. Presentation and verification

- [ ] 4.1 Style the top-bar profile control at wide and compact widths and verify it keeps a 48 by 48 target without crowding the menu or wordmark.
- [ ] 4.2 Add browser tests for top-bar navigation, drawer account order, local and remote author links, remote profile failure, and ban actor normalization.
- [ ] 4.3 Run `npm run compile`, `npm test`, and `npm run test:browser` with the real backend where safe, and record exact results.
- [ ] 4.4 Run `openspec validate refine-profile-entry-and-handles --strict` and verify no artifact or scenario errors.
