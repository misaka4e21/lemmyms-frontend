# Proposal

## Why

Community cards and forms currently describe `eligible_users` as a permission policy, although the API has no such policy field. This makes the interface promise access rules that the server does not implement and obscures the visibility and moderator posting rules the server actually enforces.

## What Changes

- Remove the `eligible_users` and `members` read/post policy controls and payload fields from community creation and management.
- Show community visibility and moderator-only posting using values returned by the API on directory cards and community pages.
- Keep account-specific actions and permissions grounded in server-returned roles, action state, and API responses.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: Community permission controls and summaries must reflect the API's visibility and moderator-only posting fields, without inventing eligibility policies.

## Impact

Changes the Elm community creation and management forms, community DTO decoding, directory cards, community detail summaries, and localized permission labels. No backend API or authorization behavior changes are proposed.
