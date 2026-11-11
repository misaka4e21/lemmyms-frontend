## Context

The browser already decodes notification kinds and keeps private-message notifications as a placeholder. The v4 API exposes message creation, editing, deletion, and reporting, but no sent-message list or standalone conversation read. Multi-community routes and DTOs are present in the backend and absent from the frontend. See `proposal.md` for motivation.

## Goals / Non-Goals

**Goals:**

- Use the notification feed as the private-message inbox and add a composer for new messages and replies.
- Add message editing, deletion, reporting, and administrator report resolution within the actions the API supports.
- Add multi-community discovery, detail feeds, creation, settings, member entries, and follow state.
- Keep permissions, deletion state, cursor pagination, and server errors authoritative.

**Non-Goals:**

- A sent-message list or a separate conversation thread endpoint that v4 does not provide.
- Message search, attachment upload, and real-time delivery.
- Multi-community federation administration or deployment-wide site controls.
- Replacing the existing notification inbox with a new messaging service.

## Decisions

### Private-message data and inbox

Expand the domain model from a message identifier to a full private-message view with creator, recipient, content, timestamps, and deleted/removed flags. The notification feed already returns this view under `data.type_ = private_message`, so the inbox becomes a filtered notification read rather than a new endpoint. The messages filter sends `type_=private_message` through the existing notification list and keeps the same cursor path.

Message cards render sanitized Markdown. The action set depends on the viewer and the message state: the creator gets edit and delete, the recipient gets delete and report, and unread recipients get mark-read. Deleted or removed messages stop showing their body. The application does not add an optimistic sent-message row to the inbox because the next fetch would drop it.

### Message composer

A new `/create_private_message/:recipient_id` route loads the recipient by `person_id` and owns a dedicated composer model. The composer reuses the shared Markdown authoring state, sends `content` and `recipient_id`, and preserves the draft on failure. A successful send returns to the recipient profile with a localized confirmation. The message action on a profile is hidden for the signed-in person and when the account has private messages disabled; the backend remains the final check for recipient settings and blocks.

### Message reports

Extend the existing report target type with a private-message target. Reporting reuses the shared reason validation and dialog. The administrator report workspace decodes private-message reports, shows the reporter, message creator, reason, and conclusion, and resolves them through the private-message report endpoint. There is no message permalink, so the report card shows the message content directly.

### Multi-community routes and feed

Add `/multi_communities`, `/create_multi_community`, `/m/:name`, and `/m/:name/settings`. The directory uses the multi-community list endpoint with listing type, sort, search term, and cursor. The detail route loads the multi-community by name and requests posts with `multi_community_name`, so the existing post decoder and card presentation remain unchanged. The detail feed fixes the listing type to `all` because the multi-community name already scopes the result.

The directory offers local and all listings to everyone and adds subscribed for authenticated readers. The default is local with subscriber sort, matching the backend defaults. The Communities page links to the directory and creation form; the primary drawer destinations stay unchanged.

### Multi-community management

Creation and settings use a separate management feature module. Creation sends name, title, summary, and sidebar, then enters `/m/:name`. Settings loads the detail response, pre-fills the editable fields, and uses the existing Markdown authoring surface for the sidebar. Delete and restore are one edit request with the requested `deleted` state. Member communities are added through a community search and removed by entry identifier pair; the member list refreshes from the detail response after each success.

Management controls appear only when the signed-in person is the creator or a site administrator. The server still enforces this rule. The 50-entry limit is a localized failure, not a client-side cap that silently disables the form.

### Follow state

The detail view reads `follow_state` from `MultiCommunityView`. Following a local multi-community returns accepted; following a remote one returns pending. The UI shows that returned state and does not infer membership from a successful request.

## Risks / Trade-offs

- **The inbox cannot show sent messages** → Confirm each send on the recipient profile and avoid a sent tab that would be empty after the next notification read.
- **A reply is absent from the list until the other person responds** → Keep the composer confirmation and explain that messages come from the notification feed.
- **Remote follow is pending** → Render the returned pending state and keep content access unchanged.
- **Directory and feed sorts use different enums** → Parse sort values per route instead of sharing one decoder that accepts every value.
- **Management actions can fail after the detail loads** → Refresh the detail on success and keep the form values plus a localized failure on error.
- **Deleted multi-communities may disappear from reads** → Treat the unavailable response as the source of truth and do not reconstruct a deleted detail page.

## Migration Plan

1. Add route constructors and query parsing for messages and multi-communities.
2. Extend domain decoders and request encoders for private messages and multi-communities.
3. Add the message composer and notification-backed message actions.
4. Add private-message report submission and administrator resolution.
5. Add the multi-community directory, detail feed, creation, settings, entries, and follow state.
6. Add localization, navigation links, browser tests, and real-backend acceptance.
7. Roll back by reverting the change commit. No backend or data migration is involved.
