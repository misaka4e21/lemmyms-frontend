# Design

## Context

`Ui.PostCard` and `Ui.CommentCard` already share the `card`, `metadata`, and `post-actions` styles. The reply card currently renders its author as the heading, only the timestamp as metadata, then Markdown and the action row. The post card adds community metadata and a more complete content hierarchy. Search results use the shared reply renderer, while profile comment results have a separate compact renderer. See `proposal.md` and `specs/forum-application/spec.md` for scope and behavior.

## Goals / Non-Goals

**Goals:**

- Reuse the topic card's existing visual language for reply headings, metadata, content spacing, and actions.
- Add community context to reply metadata using the already available `CommentView.post` data.
- Keep author identity clear and keep reply navigation, nested replies, and permission-gated actions intact.

**Non-Goals:**

- Change API requests, response decoding, permissions, or backend behavior.
- Replace the comment tree with post cards or change discussion nesting and ordering.
- Change the post card layouts or introduce a new site-wide card design system.

## Decisions

- Keep the reply card as a distinct semantic component and retain its comment content and actions. Share presentation through existing card classes and narrowly scoped CSS rather than rendering a post card for a comment; post and comment data and actions differ.
- Keep the author as the prominent reply heading and add community and timestamp to metadata, using the same links and metadata pattern as the post card. Keep the heading associated with the reply and author so existing focus and accessibility references remain valid.
- Align profile comment rows to the same heading, metadata, and content spacing while preserving their existing discussion permalink and leaving their available actions unchanged.
- Align CSS spacing and typography for the comment heading, rendered Markdown, and action row with the post card. Avoid styling selectors that alter cards in unrelated features.
- Do not add new API data requirements: the comment view already carries its creator, post, and publication time.

## Risks / Trade-offs

- [Long author or community names can wrap and increase card height] → Reuse the existing metadata wrapping behavior and allow headings to wrap.
- [Shared class changes could affect unrelated cards] → Prefer comment-specific selectors or selectors scoped to `.comment-card` and confirm other `.card` consumers are unaffected.

## Migration Plan

No data or API migration is required. Deploy the frontend presentation change normally; rollback consists of reverting the frontend changes.
