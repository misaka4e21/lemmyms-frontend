## 1. Handle helpers

- [x] 1.1 Add `Domain.profileHandle` for local versus remote people and an own-profile matcher for single-name and local-acct forms, and verify unit tests cover both.
- [x] 1.2 Normalize administrator ban actor URLs by local host or remote host, and verify local URLs produce a bare name and remote URLs keep `name@domain`.

## 2. Profile entry

- [x] 2.1 Make the authenticated drawer identity header a link to the own profile while keeping the avatar, display name, username, and role text, and verify its route, accessible name, and modal-drawer closure.
- [x] 2.2 Remove the drawer Profile destination and leave the application bar without a profile control, and verify the authenticated account list order and bar contents.

## 3. Handle call sites

- [x] 3.1 Use the shared handle for post and comment author links, community moderator links, and search person links, and verify local and remote fixtures.
- [x] 3.2 Use the shared handle unchanged in `/person` and `/person/content` reads, and verify local requests omit the hostname and remote requests retain it.
- [x] 3.3 Treat both own local handle forms as the own profile and verify own tabs, including the explicit `name@host` route.

## 4. Presentation and verification

- [x] 4.1 Style the drawer profile header link with hover and focus states and verify it keeps a 48 by 48 target without horizontal overflow at narrow widths.
- [x] 4.2 Add browser tests for drawer header navigation, modal drawer closure, absence of a top-bar profile control, drawer account order, local and remote author links, remote profile failure, and ban actor normalization.
- [x] 4.3 Run `npm run compile`, `npm test`, and `npm run test:browser` with the real backend where safe, and record exact results.
- [x] 4.4 Run `openspec validate refine-profile-entry-and-handles --strict` and verify no artifact or scenario errors.
