## 1. Contract foundation

- [x] 1.1 Extend `Lemmy.Domain` with community tags, tag lists on post and community views, person actions on post and comment views, vote views, and the tagged person-content page, and verify decoder tests cover present and absent fields.
- [x] 1.2 Add `Api.uploadTo` for arbitrary same-origin multipart targets and verify an upload test observes the target URL and file part.
- [x] 1.3 Add route query helpers for listing type, sort, time range, view mode, profile view, and search kind, including cursor-free replacement, and verify route tests cover each round trip.

## 2. Listing and presentation

- [x] 2.1 Add the shared listing-control component with native labeled selects and verify keyboard changes update the URL and request.
- [x] 2.2 Read listing, sort, time range, and view state in `Feature.Feed` and `Feature.Community`, send the supported v4 parameters, and verify a browser test sees the expected query string.
- [x] 2.3 Render list, card, and small-card post modes with thumbnails, alt text, tags, and NSFW reveal, and verify the browser test covers each mode and the reveal control.
- [x] 2.4 Decode and render post-detail cross-posts, and verify the fixture with and without cross-posts.

## 3. Actions and moderation

- [x] 3.1 Add mark-read and block author or community actions to post cards and verify successful requests and route refresh.
- [x] 3.2 Add post remove, lock, and community feature actions with permission gating and server refresh, and verify each mutation request and 403 state.
- [x] 3.3 Add comment remove, lock, and distinguish actions with permission gating and server refresh, and verify each mutation request and 403 state.
- [x] 3.4 Add the vote-list dialog for posts and comments with loading, empty, error, and keyboard dismissal states, and verify the browser test.
- [x] 3.5 Group secondary post and comment actions in an accessible disclosure menu and verify focus returns to the trigger.

## 4. Community metadata

- [x] 4.1 Decode the full community response in `Feature.Community`, render icon, banner, tags, moderator list, and notification mode, and verify the community browser fixture.
- [x] 4.2 Add community notification mode changes and verify the request and refreshed community actions.
- [x] 4.3 Add tag creation and deletion to community settings and verify the refreshed tag list.
- [x] 4.4 Add community icon and banner uploads to community settings and verify the multipart target and refreshed header.

## 5. Search and profiles

- [x] 5.1 Expand search kinds to all, comments, posts, communities, users, and URL, and verify the v4 query mapping and cursor preservation.
- [x] 5.2 Render resolved objects and the post, comment, community, and person result lists, and verify empty and error states.
- [x] 5.3 Add public profile posts and comments tabs through person content and verify cursor pagination.
- [x] 5.4 Add own-profile saved, liked, read, and hidden tabs through the account collections and verify forbidden and empty states.
- [x] 5.5 Add accessible tab semantics and focus movement to profile tabs and verify the keyboard browser test.

## 6. Localization and verification

- [x] 6.1 Add the new Fluent keys to all three catalogs, regenerate the Elm bindings and hashed JSON, and verify `npm run i18n:check`.
- [x] 6.2 Update mock browser fixtures and add browser tests for listing controls, NSFW reveal, moderation actions, vote lists, tags, uploads, search types, and profile tabs.
- [x] 6.3 Run `npm run compile`, `npm test`, and `npm run test:browser`, and record the exact results and any environment-limited checks.
- [x] 6.4 Run `openspec validate complete-browsing-and-moderation --strict` and verify the change reports no artifact or scenario errors.
