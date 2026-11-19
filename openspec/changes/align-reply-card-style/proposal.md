# Proposal

## Why

Replies currently use a more abbreviated card than topic posts: they omit community context and their heading, metadata, body, and action area do not follow the same visual hierarchy. This makes replies harder to scan and gives them a visibly different treatment in the discussion.

## What Changes

- Align reply cards with the topic post card's surface, spacing, title and metadata hierarchy, content spacing, and action row.
- Show the reply author, community, and publication time in the reply card's metadata, while retaining the reply's own content and available actions.
- Keep reply-specific behavior such as nested replies, moderation controls, voting, and saving intact.
- Limit the work to the frontend; do not change backend code or API behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: Specify a consistent visual hierarchy for reply cards and topic post cards while preserving reply-specific content and actions.

## Impact

- Frontend rendering in `src/Ui/CommentCard.elm` and shared card styles in `src/style.css`; the discussion card composition in `src/App/View/Content.elm` may need adjustment.
- No API, dependency, or backend changes.
