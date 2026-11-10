## 1. Fix and Verify Community Directory Sort

- [x] 1.1 Replace the community directory `sort=top` query with a supported `CommunitySortType` value (`active_monthly`) in `src/Feature/Community.elm`; verify the request builds without unsupported values and `npm run compile` passes.
- [x] 1.2 Extend the v4 mock browser suite to assert the `/api/v4/community/list` request uses an allowed community sort and that the directory renders the returned community; verify `npx playwright test tests-browser/forum.spec.js` passes.
- [x] 1.3 Extend the real-backend acceptance flow to open `/communities` and see the created community; verify the real-backend Playwright test passes against `http://localhost:8536`.
- [x] 1.4 Run `npm run compile`, `npm test`, `npm run i18n:check`, `npm run format:check`, and `npm run test:browser`; record any environment-only failure separately.
