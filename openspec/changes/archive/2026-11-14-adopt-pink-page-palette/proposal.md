## Why

The page palette is currently purple (`--md-primary`, surfaces, top bar gradient). The product direction calls for a pink branded surface while keeping the existing accent pink (`--md-accent`) and preserving WCAG 2.2 AA contrast. This change converts the purple base tokens to pink and removes the top-bar gradient in favor of a single flat pink stop, so the accent no longer competes with the primary hue.

## What Changes

- Replace the purple `:root` and dark-mode token set (`--md-primary`, containers, on-surface, on-surface-variant, outline, focus, top-bar) with pink equivalents. Page surface (`--md-surface`) becomes pure white in light mode; surface-container tokens become neutral grays.
- Replace the three-stop top-bar gradient with a single flat pink stop (`--md-top-bar`), dropping `--md-top-bar-start/mid/end`.
- Darken `--md-accent` so it reads as a distinct emphasis color against the new pink primary.
- Update the `theme-color` meta in `index.html` to the new pink bar value.
- Update `docs/accessibility-and-testing.md` contrast table to the new values.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `accessible-material-interface`: the branded application bar and primary palette move from purple to pink; the bar is now a flat single-color surface rather than a gradient. Contrast thresholds remain unchanged.

## Impact

- `src/style.css` token definitions (light and dark).
- `index.html` `theme-color` meta.
- `docs/accessibility-and-testing.md` evidence table.
- `tests-js/palette.test.js` assertions for top-bar stops need updating to the single stop.
