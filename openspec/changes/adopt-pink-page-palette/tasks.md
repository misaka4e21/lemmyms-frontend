## 1. Palette tokens

- [x] 1.1 Replace purple `:root` and dark-mode tokens in `src/style.css` with pink equivalents and verify the file parses
- [x] 1.2 Replace `--md-top-bar-start/mid/end` with single `--md-top-bar` in `src/style.css` and verify no remaining references to the old names
- [x] 1.3 Darken `--md-accent` in both themes and verify contrast against the new surface

## 2. Consumers

- [x] 2.1 Update `index.html` `theme-color` meta to the new bar value and verify by reading the file
- [x] 2.2 Update `tests-js/palette.test.js` to assert the single `md-top-bar` stop and verify `npm test` passes
- [x] 2.3 Update `docs/accessibility-and-testing.md` contrast table and verify values match the stylesheet

## 3. Verification

- [x] 3.1 Run `npm run build` and verify emitted CSS contains the new tokens
- [x] 3.2 Run `npm run test:browser` and verify axe reports zero violations on the pink palette
