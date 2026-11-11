## 1. Routes and data contracts

- [x] 1.1 Add `CreatePrivateMessage Int`, `MultiCommunities`, `CreateMultiCommunity`, `MultiCommunity String`, and `MultiCommunitySettings String` routes, and parse the notifications `kind` filter; verify route tests cover direct loads and generated paths.
- [x] 1.2 Expand the private-message view decoder, add multi-community and multi-community-detail decoders, and decode private-message report targets; verify unit tests cover full fields and optional flags.
- [x] 1.3 Add query and body builders for notification filters, message create/edit/delete/report, multi-community list/detail/create/edit/entry/follow, and post listings by multi-community name; verify request-shape tests cover each endpoint.

## 2. Private messages

- [x] 2.1 Add the messages filter to `/notifications?kind=messages` with notification type `private_message` and cursor pagination; verify the browser mock receives the filter and the visible list changes.
- [x] 2.2 Render private-message notifications as articles with author link, sanitized Markdown body, timestamp, and deleted or removed state; verify the browser shows the full message and hides deleted bodies.
- [x] 2.3 Add mark-read, reply, edit, and delete actions with creator, recipient, and deletion gating; verify each request is sent only for the permitted role.
- [x] 2.4 Add the composer route that loads the recipient by identifier, reuses Markdown authoring, sends content and recipient, and preserves the draft on failure; verify route, success, and failure browser flows.
- [x] 2.5 Add the profile message action and hide it for the signed-in person or a disabled private-message setting; verify the action routing and the disabled state.
- [x] 2.6 Add private-message reporting to the shared report dialog with the same reason validation; verify the create request carries the message identifier and reason.
- [x] 2.7 Display private-message reports in the administrator report workspace and resolve or reject them; verify the resolve request carries the report identifier, resolution, and optional conclusion.

## 3. Multi-communities

- [x] 3.1 Add the `/multi_communities` directory with local, all, and subscribed listings, supported sorts, search text, and cursor pagination; verify each filter resets the cursor and updates the URL.
- [x] 3.2 Add multi-community cards and a Communities page link plus creation entry point; verify keyboard navigation reaches the directory and creation form.
- [x] 3.3 Add `/m/:name` loading by name and render the title, summary, sidebar, owner, counts, and member communities; verify direct loading and unavailable states.
- [x] 3.4 Add the multi-community post feed using `multi_community_name` with sort, time range, and cursor; verify the request and the rendered post list.
- [x] 3.5 Add follow and unfollow actions with accepted, pending, and anonymous states; verify local accepted and remote pending responses update the control.
- [x] 3.6 Add `/create_multi_community` with name, title, summary, and sidebar; verify success enters the new detail route and failure keeps the form values.
- [x] 3.7 Add `/m/:name/settings` with title, summary, and sidebar editing; verify the edit request and refreshed detail.
- [x] 3.8 Add delete and restore actions with confirmation; verify the edit request carries the requested deleted state and the navigation follows success.
- [x] 3.9 Add member-community search, add, and remove actions, including the 50-entry limit failure; verify the entry requests and the localized limit state.
- [x] 3.10 Gate management controls to the creator or a site administrator; verify an ordinary reader sees no mutating controls and sends no management request.

## 4. Presentation and localization

- [x] 4.1 Make the composer, message cards, messages filter, and report dialog keyboard accessible with persistent labels, announced errors, and focus return; verify with browser keyboard flows and the axe check.
- [x] 4.2 Make the directory controls, create and settings forms, entry picker, follow control, and limit errors accessible; verify labels, error associations, and no page-level horizontal scrolling at narrow widths.
- [x] 4.3 Add the private-message and multi-community Fluent keys, regenerate Elm bindings and hashed catalogs, and verify `npm run i18n:check` and all three locale catalogs.
- [x] 4.4 Add responsive styles for message entries, multi-community cards, forms, and the entry picker; verify wide and compact layouts retain the 48-pixel controls and readable text.

## 5. Verification

- [x] 5.1 Run `npm run compile` and `npm test`; verify compilation, JavaScript tests, Elm domain and route tests, and formatting pass.
- [x] 5.2 Run the full browser suite; verify message composition, message actions, message reports, multi-community discovery, detail feed, follow, creation, settings, entries, and accessibility checks.
- [x] 5.3 Run the real-backend acceptance where safe; verify message send, notification-backed message read, multi-community creation, entry changes, follow, and feed reads, recording any environment limits.
- [x] 5.4 Run `openspec validate add-private-messages-and-multi-communities --strict` and `git diff --check`; verify no artifact or scenario errors and no whitespace problems.
