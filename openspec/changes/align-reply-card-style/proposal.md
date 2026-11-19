# Proposal

## Why

Reply cards currently display the author as a large heading, while topic cards place author identity in the metadata row. This gives replies a different hierarchy and gives author information more prominence than the reply itself.

## What Changes

- Align reply cards with the topic post card's surface, spacing, metadata hierarchy, content spacing, and action row.
- Remove the large author heading. Show the author name and account, community, and publication time in a metadata row styled like the topic post metadata; keep the reply content in the regular body text.
- Keep reply-specific behavior such as nested replies, moderation controls, voting, and saving intact.
- Limit the work to the frontend; do not change backend code or API behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: Specify a consistent visual hierarchy for reply cards and topic post cards while preserving reply-specific content and actions.

## Impact

- Frontend rendering in `src/Ui/CommentCard.elm` and `src/Feature/Profile.elm`, plus shared card styles in `src/style.css`.
- No API, dependency, or backend changes.
