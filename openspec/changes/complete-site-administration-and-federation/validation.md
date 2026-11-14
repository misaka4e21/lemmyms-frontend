# Validation

Checked on 2026-11-13 against the local frontend and the LemmyMultisite test server at port 8536.

- `ELM_HOME=/tmp/elm-home-lemmyms npm test`: 18 JavaScript tests and 73 Elm tests passed.
- `ELM_HOME=/tmp/elm-home-lemmyms npx elm make src/Main.elm --output=/tmp/lemmy-p4-main.js`: compiled successfully.
- `npm run format:check` and `npm run i18n:check`: passed.
- `COMMUNE_TEST_URL=http://127.0.0.1:4174 COMMUNE_TEST_ELM_JS=/tmp/lemmy-p4-main.js npx playwright test tests-browser/forum.spec.js`: 59 browser tests passed, including site configuration accessibility and keyboard checks.
- `COMMUNE_REAL_BACKEND=1 COMMUNE_REAL_BACKEND_URL=http://127.0.0.1:4175 COMMUNE_TEST_ELM_JS=/tmp/lemmy-p4-main.js npx playwright test tests-browser/real-p4-readonly.spec.js`: passed with the test administrator password supplied in the environment. This test performs login and read requests only; it does not establish tenant isolation or exercise live mutations.
- `openspec validate complete-site-administration-and-federation --strict` and `git diff --check`: passed.

The site media cache, registration review, global media deletion, purge, and OAuth cookie limitations recorded in `backend-audit.md` remain outside the scope of these results. The test server has not been used to make live configuration changes.

On 2026-11-14, all 60 browser tests passed after associating invalid fields with their error message, adding a live loading status, and reporting registration conflicts. They cover keyboard cancellation, cleared legal text, both site images, and preservation of failed drafts. An additional automated accessibility scan passed on ten administration, review, and federation pages. Elm compilation, 18 JavaScript tests, 73 Elm tests, format, catalog consistency, and `git diff --check` also passed.

The federation policy browser test was subsequently rerun with an invalid block expiry. It verifies the associated error, disabled submission, and recovery when a valid expiry is entered. The P4 accessibility scan, Elm compilation, format, and catalog consistency checks passed again.
