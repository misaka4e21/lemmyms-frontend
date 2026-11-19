# Design

## Context

See proposal.md for the motivation. The current Elm forms keep `readPolicy` and `postPolicy` values such as `eligible_users` and `members`, and the community card derives its post label from `posting_restricted_to_mods`. The v4 community API accepts `visibility` and `posting_restricted_to_mods`; post creation checks the latter against the authenticated person's community moderator status. The community DTO already decodes both fields.

## Goals / Non-Goals

**Goals:**

- Use the API's community fields as the source for displayed visibility and posting restrictions.
- Keep personal action availability tied to returned viewer state and server authorization outcomes.
- Remove policy fields that have no API contract.

**Non-Goals:**

- Changing backend authorization or adding new community access policies.
- Inferring an account's eligibility from identity, community name, or description text.

## Decisions

- Keep visibility and posting restriction as separate values throughout the interface. Visibility describes who can access the community; `posting_restricted_to_mods` describes who may create posts when enabled.
- Remove the read/post policy values from create and manage forms and request payloads. The existing API request fields remain the form contract.
- Render visibility on directory cards and community detail pages. Show a posting label only when the API restricts posts to moderators; omit it when no moderator-only restriction applies.
- Treat server-returned viewer roles/actions as the only basis for personalized controls. Let authorization failures from mutations update the visible state through existing error handling.

## Risks / Trade-offs

- [Existing communities may have been described with the old generic label] → Render their actual API fields after the change, so the displayed rule may differ from the label users saw before.
- [The API does not expose a generic per-viewer eligibility explanation] → Show community-level rules and use action state or server responses for personalized permissions; do not invent an explanation.

## Migration Plan

No data migration is required. Remove the client-only policy fields from forms and payloads, then deploy the frontend. Rolling back restores the prior labels and controls without changing stored community data.
