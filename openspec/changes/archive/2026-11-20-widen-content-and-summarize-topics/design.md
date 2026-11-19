# Design

## Context

See proposal.md for the motivation. `.page-content` currently has a fixed 760px maximum width while `.content-column` already tracks the available grid width. `Ui.PostCard` renders `post.body` for every context. The current `Domain.Post` decoder has no summary field, and the application uses the same card renderer for topic feeds, search results, profiles, and discussion pages.

## Goals / Non-Goals

**Goals:**

- Use more of the available right-side layout width while preserving a readable line length and side margins.
- Keep post lists compact and discussion content complete.
- Prevent Markdown content from creating page-level horizontal overflow.

**Non-Goals:**

- Changing server endpoints or post mutations.
- Truncating replies or full post discussion content.
- Changing the visual layout modes selected by the reader.

## Decisions

- **Use fluid width with a maximum reading width.** Set the page content width as a responsive proportion of its parent, bounded by a larger maximum than 760px and centered within the available column. This lets a desktop layout use spare width while preventing very long text lines. Keep existing small-screen gutters.
- **Make topic-list rendering context explicit.** Add a card display context for topic-list excerpts versus full content. Route listing contexts such as feed, community posts, search results, profile posts, and account or multi-community post lists through excerpt mode. The discussion post card remains full; reply cards are independent and remain unchanged.
- **Use Lemmy's optional link description when available, then derive an excerpt from Markdown body.** The current Lemmy API type exposes `embed_description` for link posts, not a general post `summary`; decode that field optionally. For cards without a non-empty description, parse the Markdown into plain text, bound it by a fixed character limit, and append an ellipsis when content was omitted. Render excerpts as text so Markdown syntax does not leak into the card or partially render complex blocks.
- **Scope overflow handling to rendered Markdown.** Allow text to wrap at arbitrary boundaries. Give code and other intrinsically wide blocks a local horizontal scroll region; cap images and other media to the container width. Avoid hiding overflow at the page root, which could conceal content.

## Risks / Trade-offs

- [Summary availability differs by server version] → Decode the summary as optional and use the body excerpt when missing or blank.
- [Excerpting Markdown can cut a formatted span or URL] → Convert the source to a plain-text excerpt before truncation and append an omission marker.
- [A larger maximum can make paragraphs harder to scan on ultrawide screens] → Keep a bounded maximum and tune it against the content column rather than allowing unlimited growth.

## Migration Plan

No data migration is required. The UI changes can ship together. Rollback consists of reverting the layout and card presentation changes; API data remains unchanged.
