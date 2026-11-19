# Tasks

## 1. Responsive content width and overflow

- [x] 1.1 Replace the fixed `.page-content` width with a fluid width and bounded maximum; verify desktop content uses more available right-side space while mobile gutters remain intact.
- [x] 1.2 Add scoped Markdown overflow rules for long text, code blocks, tables, and media; verify wide content stays inside its card without page-level horizontal scrolling.

## 2. Topic card summaries

- [x] 2.1 Confirm the v4 post DTO's optional `embed_description` field and decode it optionally; verify responses with and without the field decode successfully.
- [x] 2.2 Add explicit excerpt/full display context to post cards and route topic listing surfaces through excerpt mode; verify discussion pages retain full post bodies and reply cards remain unchanged.
- [x] 2.3 Prefer a non-empty summary and otherwise generate a bounded plain-text excerpt from the body with an omission marker; verify missing, blank, short, and long body cases.

## 3. Browser behavior coverage

- [x] 3.1 Extend browser coverage for dynamic content width, overflow containment, summary preference, body fallback, and full discussion rendering; verify the focused browser specs pass.
