## Why

The frontend now covers browsing, moderation, and account settings, but two lemmy-ui areas remain absent. Private-message notifications render as an unavailable placeholder and there is no way to start a message. Multi-community discovery, reading, creation, and management are missing even though the v4 API exposes them. These gaps leave the migration incomplete for readers who rely on direct messages or grouped community feeds.

## What Changes

- Decode full private-message views in notification data, including creator, recipient, content, timestamps, and the deleted and removed flags.
- Render private messages as message entries in the notification feed with mark-read, reply, edit, delete, and report actions gated by ownership and deletion state.
- Add a messages filter to `/notifications?kind=messages` that requests notification type `private_message`.
- Add the `/create_private_message/:recipient_id` composer, reachable from another person's profile and from a message reply, and send `POST /private_message`.
- Add private-message reporting and the administrator resolve action for those reports.
- Add the `/multi_communities` directory with listing type, sort, search, and cursor pagination.
- Add `/create_multi_community` for name, title, summary, and sidebar.
- Add `/m/:name` with the multi-community metadata, member communities, follow state, and its post feed.
- Add `/m/:name/settings` to edit the title, summary, and sidebar, mark the multi-community deleted or restored, and add or remove member communities through community search. The backend's 50-entry limit SHALL be reported as a localized failure.
- Extend routes, DTO decoding, request metadata, navigation, localization, browser tests, and real-backend acceptance.
- Use the v4 notification feed as the private-message inbox. The API has no sent-box or standalone conversation-read endpoint, so sent messages are confirmed after creation but are not retained as a separate sent list.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: private-message composition, notification-backed inbox actions, private-message reports, and multi-community directory, detail, feed, creation, settings, entries, and follow behavior.
- `lemmy-api-integration`: private-message DTOs and requests, notification type filtering, private-message report requests, multi-community CRUD and entry requests, and post listings scoped by multi-community name.
- `accessible-material-interface`: accessible message composer, message cards and filters, private-message report controls, multi-community directory and forms, entry picker, and follow feedback.

## Impact

- Frontend modules: `src/Lemmy/Domain.elm`, `src/Lemmy/Route.elm`, `src/App/Routing.elm`, `src/App/Features.elm`, `src/App/State.elm`, `src/App/View.elm`, `src/App/View/Content.elm`, `src/App/Shell.elm`, `src/Feature/Notifications.elm`, `src/Feature/Profile.elm`, `src/Feature/Report.elm`, `src/Feature/SiteAdmin/*`, and new private-message and multi-community feature modules.
- Presentation: message cards and composer, notification filters, multi-community directory/detail cards, create and settings forms, community entry picker, follow control, and localized empty, error, and permission states.
- Localization: new Fluent keys in `translations/messages.*.ftl`, regenerated `src/Generated/I18n.elm`, and hashed JSON catalogs.
- Tests: route and DTO tests, message action gating and composer failures, notification filtering, private-message report flows, multi-community directory/create/detail/settings/entry/follow flows, and real-backend acceptance where safe.
- Backend: no change. The implementation uses `POST /private_message`, `PUT /private_message`, `DELETE /private_message`, `POST /private_message/report`, `PUT /private_message/report/resolve`, `GET /account/notification/list?type_=private_message`, `POST /multi_community`, `PUT /multi_community`, `GET /multi_community`, `GET /multi_community/list`, `POST /multi_community/entry`, `DELETE /multi_community/entry`, `POST /multi_community/follow`, and `GET /post/list?multi_community_name=`.
