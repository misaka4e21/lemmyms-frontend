# Proposal

## Why

Post text can run wider than the page's useful reading area, while the main content column stays capped at 760px even when the right side of the layout has more room. Topic lists also render full post bodies, making long feeds hard to scan.

## What Changes

- Let the main content width respond to the space available beside the navigation drawer while keeping readable margins and a sensible maximum line length.
- Constrain overflowing Markdown content, including long unbroken text, code, and media, to the content area.
- Show a post summary in topic lists when one is available. When it is absent, show a bounded excerpt from the post body.
- Keep full post text on the discussion page and full reply text in reply lists.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: define responsive content width and overflow behavior, and distinguish topic list excerpts from full post and reply content.

## Impact

- Layout styles in `src/style.css`.
- Post card rendering and post DTO decoding in `src/Ui/PostCard.elm`, `src/App/View/Content.elm`, and `src/Lemmy/Domain.elm`.
- Browser coverage in `tests-browser/forum.spec.js`.
- No API requests or mutations are changed. The client will decode an optional summary if the post response provides one, with a body excerpt as the fallback.
