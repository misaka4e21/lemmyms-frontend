## Context

All color values live in `src/style.css` as CSS custom properties; no component-level color literals exist. The palette is split into `:root` (light) and `:root[data-theme="dark"]`. Contrast assertions live in `tests-js/palette.test.js`, which parses the stylesheet and recomputes ratios. The archived `adopt-blue-purple-header-palette` change established the precedent of a branded top bar with white foreground and a focus ring.

## Goals / Non-Goals

**Goals:**

- Convert the purple base palette to pink in both themes.
- Replace the three-stop top-bar gradient with a single flat pink stop.
- Keep every existing contrast assertion passing (top bar >= 4.5:1, focus ring >= 3:1, accent >= 4.5:1, error >= 4.5:1, zero badge >= 4.5:1).
- Update `theme-color` meta and the docs evidence table.

**Non-Goals:**

- No component or Elm source changes; tokens only.
- No new color tokens beyond replacing the three bar stops with one.
- No changes to forced-colors or reduced-motion behavior.

## Decisions

- **Pink primary**: `#b3265e` (light) / `#ffb1c9` (dark). Chosen so white text clears 4.5:1 on the bar and primary text clears 4.5:1 on the surface. Darker than the existing accent (`#c2185b`) so the two no longer collide.
- **Accent darkened** from `#c2185b` to `#9c1b4a` (light) so it stays distinct from the new primary while still clearing 4.5:1 on the light surface.
- **Flat bar**: a single `--md-top-bar` token replaces `--md-top-bar-start/mid/end`. Simpler and avoids the gradient compositing problem; the bar is now one solid pink surface.
- **Surfaces**: shifted from lavender (`#fbf8ff`) to pale pink (`#fff0f6`) so the whole page reads pink, not just the primary.
- **theme-color**: set to the single bar value `#b3265e`.

## Risks / Trade-offs

- [Risk] Dark-mode palette is not covered by `palette.test.js`. Mitigation: manually verify contrast with the same script used during exploration.
- [Risk] Removing the gradient changes the visual identity established by the archived header-palette change. Mitigation: documented in the spec and docs table.
- [Risk] `tests-js/palette.test.js` references the three old stop names; must be updated to `md-top-bar`.

## Migration Plan

1. Edit `src/style.css` light and dark `:root` blocks.
2. Replace gradient usage with `--md-top-bar` (search for `md-top-bar-start/mid/end`).
3. Update `index.html` `theme-color`.
4. Update `tests-js/palette.test.js` stop list.
5. Update `docs/accessibility-and-testing.md` table.
6. Run `npm test`, `npm run build`, `npm run test:browser`.

## Open Questions

(none)
