## 1. Route contract

- [x] 1.1 Extend `src/Lemmy/Route.elm` with the application-specific account, password, administration, and comment-edit routes from the design route table, and verify `elm make src/Main.elm` still compiles.
- [x] 1.2 Add route tests for every canonical path, app-specific alias, query round trip, and former Commune path, and verify `elm-test` passes.
- [x] 1.3 Switch `Main`, `App.Routing`, `App.View`, and the view adapters from `Route` to `Lemmy.Route`, delete `src/Route.elm`, and verify no `import Route` remains.
- [x] 1.4 Replace remaining `Route.query`, `Route.cursor`, `Route.path`, and `Route.parse` usages with the `Lemmy.Route` equivalents, remove the unused offset helper, and verify the full Elm test suite passes.

## 2. Community routes by name

- [x] 2.1 Change `Feature.Community` to read `/community?name=:name` and request topics with the returned community ID, and verify direct loads and back/forward navigation in the browser test.
- [x] 2.2 Change `Feature.CommunityManage` context and state to carry the community name, derive the integer ID after the community loads, and verify follow approval, moderator changes, bans, and report resolution still issue the expected requests.
- [x] 2.3 Update community, management, notification, and drawer links to generate `/c/:name` and `/c/:name/settings`, and verify no generated link contains `/communities/:id`.

## 3. Comment permalinks

- [x] 3.1 Add a comment resolver that reads `/comment?id=:commentId`, decodes the containing post ID, and calls `Navigation.replaceUrl` with `/post/:postId/:commentId`, and verify the route test covers the replacement target.
- [x] 3.2 Pass the optional comment ID into the post discussion, mark the matching comment as the focus target, and focus it after the replies render, and verify the browser test observes focus on the referenced comment.
- [x] 3.3 Render a localized unavailable state for a missing, deleted, forbidden, or unreadable comment or post, and verify the mock browser test does not render an empty discussion.

## 4. Settings and administration routes

- [x] 4.1 Map `/settings` to the existing profile settings view while keeping `/settings/profile` as an alias, and verify both URLs render the same form.
- [x] 4.2 Map `/reports` and `/modlog/:communityId?` to the existing administration views while keeping `/admin/reports` and `/admin/modlog` as aliases, and verify filters and pagination still work.
- [x] 4.3 Update drawer and administration navigation to generate `/reports` and `/modlog`, and verify no generated administration link uses the old shape.

## 5. Path tokens

- [x] 5.1 Derive the verification and reset tokens from the parsed route in `App.Init`, pass them to the authentication state, and remove the verification-token flag from the flags decoder.
- [x] 5.2 Remove the `/verify_email/` and `/password_change/` rewrites from `src/bootstrap.js`, and verify both URLs keep their path segments until the form is submitted.
- [x] 5.3 Verify successful and failed token flows replace history with a token-free route and never render the token in visible text or storage.

## 6. Route cleanup

- [x] 6.1 Remove the person-report button, `Report.PersonTarget`, and its no-op submission branch, and verify no `reportPerson` reference remains in `src`.
- [x] 6.2 Reset the comment cursor on sort and depth changes and remove `offset` from the reply URL builder, and verify the route test expects a cursor-free first page.

## 7. Verification and documentation

- [x] 7.1 Update `tests-browser/forum.spec.js` to use canonical paths and add assertions for `/c/:name`, `/post/:id/:commentId`, `/comment/:id`, `/u/:name`, `/settings`, and legacy not-found behavior, and verify `npm run test:browser` passes.
- [x] 7.2 Update `tests-browser/real-backend.spec.js` to open communities through `/c/:name` and create posts through `/create_post?community_id=:id`, and verify the real-backend suite passes when the backend is available.
- [x] 7.3 Update `docs/architecture.md`, `docs/backend-integration.md`, and the route references in acceptance notes, and verify the documented route table matches the generated paths.
- [x] 7.4 Run `npm run compile`, `npm test`, and `npm run test:browser`, and record the exact results and any environment-limited checks.
- [x] 7.5 Run `openspec validate restore-canonical-lemmy-routes` and verify the change reports no artifact or scenario errors.
