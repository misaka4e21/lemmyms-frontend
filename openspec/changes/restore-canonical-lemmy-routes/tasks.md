## 1. Route contract

- [ ] 1.1 Extend `src/Lemmy/Route.elm` with the application-specific account, password, administration, and comment-edit routes from the design route table, and verify `elm make src/Main.elm` still compiles.
- [ ] 1.2 Add route tests for every canonical path, app-specific alias, query round trip, and former Commune path, and verify `elm-test` passes.
- [ ] 1.3 Switch `Main`, `App.Routing`, `App.View`, and the view adapters from `Route` to `Lemmy.Route`, delete `src/Route.elm`, and verify no `import Route` remains.
- [ ] 1.4 Replace remaining `Route.query`, `Route.cursor`, `Route.path`, and `Route.parse` usages with the `Lemmy.Route` equivalents, remove the unused offset helper, and verify the full Elm test suite passes.

## 2. Community routes by name

- [ ] 2.1 Change `Feature.Community` to read `/community?name=:name` and request topics with the returned community ID, and verify direct loads and back/forward navigation in the browser test.
- [ ] 2.2 Change `Feature.CommunityManage` context and state to carry the community name, derive the integer ID after the community loads, and verify follow approval, moderator changes, bans, and report resolution still issue the expected requests.
- [ ] 2.3 Update community, management, notification, and drawer links to generate `/c/:name` and `/c/:name/settings`, and verify no generated link contains `/communities/:id`.

## 3. Comment permalinks

- [ ] 3.1 Add a comment resolver that reads `/comment?id=:commentId`, decodes the containing post ID, and calls `Navigation.replaceUrl` with `/post/:postId/:commentId`, and verify the route test covers the replacement target.
- [ ] 3.2 Pass the optional comment ID into the post discussion, mark the matching comment as the focus target, and focus it after the replies render, and verify the browser test observes focus on the referenced comment.
- [ ] 3.3 Render a localized unavailable state for a missing, deleted, forbidden, or unreadable comment or post, and verify the mock browser test does not render an empty discussion.

## 4. Settings and administration routes

- [ ] 4.1 Map `/settings` to the existing profile settings view while keeping `/settings/profile` as an alias, and verify both URLs render the same form.
- [ ] 4.2 Map `/reports` and `/modlog/:communityId?` to the existing administration views while keeping `/admin/reports` and `/admin/modlog` as aliases, and verify filters and pagination still work.
- [ ] 4.3 Update drawer and administration navigation to generate `/reports` and `/modlog`, and verify no generated administration link uses the old shape.

## 5. Path tokens

- [ ] 5.1 Derive the verification and reset tokens from the parsed route in `App.Init`, pass them to the authentication state, and remove the verification-token flag from the flags decoder.
- [ ] 5.2 Remove the `/verify_email/` and `/password_change/` rewrites from `src/bootstrap.js`, and verify both URLs keep their path segments until the form is submitted.
- [ ] 5.3 Verify successful and failed token flows replace history with a token-free route and never render the token in visible text or storage.

## 6. Route cleanup

- [ ] 6.1 Remove the person-report button, `Report.PersonTarget`, and its no-op submission branch, and verify no `reportPerson` reference remains in `src`.
- [ ] 6.2 Reset the comment cursor on sort and depth changes and remove `offset` from the reply URL builder, and verify the route test expects a cursor-free first page.

## 7. Verification and documentation

- [ ] 7.1 Update `tests-browser/forum.spec.js` to use canonical paths and add assertions for `/c/:name`, `/post/:id/:commentId`, `/comment/:id`, `/u/:name`, `/settings`, and legacy not-found behavior, and verify `npm run test:browser` passes.
- [ ] 7.2 Update `tests-browser/real-backend.spec.js` to open communities through `/c/:name` and create posts through `/create_post?community_id=:id`, and verify the real-backend suite passes when the backend is available.
- [ ] 7.3 Update `docs/architecture.md`, `docs/backend-integration.md`, and the route references in acceptance notes, and verify the documented route table matches the generated paths.
- [ ] 7.4 Run `npm run compile`, `npm test`, and `npm run test:browser`, and record the exact results and any environment-limited checks.
- [ ] 7.5 Run `openspec validate restore-canonical-lemmy-routes` and verify the change reports no artifact or scenario errors.
