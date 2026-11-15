# Validation

Checked on 2026-11-13 against the local frontend and the LemmyMultisite test server at port 8536.

- `ELM_HOME=/tmp/elm-home-lemmyms npm test`: 18 JavaScript tests and 73 Elm tests passed.
- `ELM_HOME=/tmp/elm-home-lemmyms npx elm make src/Main.elm --output=/tmp/lemmy-p4-main.js`: compiled successfully.
- `npm run format:check` and `npm run i18n:check`: passed.
- `COMMUNE_TEST_URL=http://127.0.0.1:4174 COMMUNE_TEST_ELM_JS=/tmp/lemmy-p4-main.js npx playwright test tests-browser/forum.spec.js`: 59 browser tests passed, including site configuration accessibility and keyboard checks.
- `COMMUNE_REAL_BACKEND=1 COMMUNE_REAL_BACKEND_URL=http://127.0.0.1:4175 COMMUNE_TEST_ELM_JS=/tmp/lemmy-p4-main.js npx playwright test tests-browser/real-p4-readonly.spec.js`: passed with the test administrator password supplied in the environment. This test performs login and read requests only; it does not establish tenant isolation or exercise live mutations.
- `openspec validate complete-site-administration-and-federation --strict` and `git diff --check`: passed.

At that checkpoint, media deletion and purge changes still depended on the backend tenant-isolation fixes, and OAuth session restoration still depended on a backend cookie fix. The test server was not used to make live configuration changes.

On 2026-11-14, all 60 browser tests passed after associating invalid fields with their error message, adding a live loading status, and reporting registration conflicts. They cover keyboard cancellation, cleared legal text, both site images, and preservation of failed drafts. An additional automated accessibility scan passed on ten administration, review, and federation pages. Elm compilation, 18 JavaScript tests, 73 Elm tests, format, catalog consistency, and `git diff --check` also passed.

The federation policy browser test was subsequently rerun with an invalid block expiry. It verifies the associated error, disabled submission, and recovery when a valid expiry is entered. The P4 accessibility scan, Elm compilation, format, and catalog consistency checks passed again.

After backend commit `a7048f9fa`, frontend mock tests cover site-scoped media deletion and all four purge requests, confirmation and cancellation, failure recovery, and non-admin access. The full browser suite passed 63 tests, and 18 JavaScript and 73 Elm tests passed. The backend's isolated regression results are recorded in its archived `fix-tenant-approval-media-purge/validation.md`; they were not rerun from this frontend workspace. At that checkpoint, the debug binary predated the fix, so no live mutation was attempted.

On 2026-11-16, LemmyMultisite commit `87bbe693a` added site-view invalidation after site icon/banner uploads and set the OAuth HttpOnly session cookie. The running `target/debug/lemmy_server` binary was built after that commit; its exact embedded source revision is not exposed. The v4 endpoint returned the site when addressed with the configured `localhost` tenant host. The real-backend read-only browser suite passed, including admin access to the P4 pages.

The OAuth browser regression now models the backend's `Set-Cookie: jwt=...; HttpOnly` response, confirms the cookie is stored as HttpOnly, and accepts the session only after `/account` succeeds. The site configuration regression passed for identity, description, legal text, discussion languages, untouched fields, and icon/banner operations. A separate real-backend browser acceptance temporarily changed the site name through the UI, observed the saved value, restored the original value in `finally`, and then confirmed the original `Lemmy test server` value through a fresh API read. The operation and cleanup both completed successfully.

The two-site configuration isolation tests and media/purge tenant regression results are documented in the backend's archived `fix-site-settings-tenant-isolation` and `fix-tenant-approval-media-purge` changes. They use isolated database fixtures; they were not rerun from this frontend workspace. No setup, media deletion, purge, or other destructive operation was run against the shared 8536 test site.

Current frontend verification: `ELM_HOME=/tmp/elm-home-lemmyms npx elm make src/Main.elm --output=/tmp/lemmy-p4-main.js`, `npm test` (18 JavaScript and 73 Elm tests), `npm run format:check`, and `npm run i18n:check` passed. The focused OAuth and site configuration Playwright tests passed (2/2), the read-only real-backend suite passed (1/1), and the reversible real-backend acceptance passed (1/1). The full mocked browser suite previously passed 63 tests. OpenSpec strict validation and `git diff --check` are rerun after these documentation updates.
