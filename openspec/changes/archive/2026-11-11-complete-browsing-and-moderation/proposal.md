## Why

The v4 migration restored canonical navigation but left most browsing controls and moderation affordances out of the interface. Readers cannot choose a listing type, sort, time range, or post listing mode. Post cards omit thumbnails, cross-posts, tags, and NSFW protection. Moderators cannot remove, lock, feature, or distinguish content, inspect votes, or manage community tags and images from the client. Search only covers posts and communities, and public profiles have no content tabs.

## What Changes

- Add shared listing controls for listing type, post sort, time range, and post listing mode on the latest and community feeds. Persist the choices in the URL query and send the supported v4 parameters.
- Add post presentation for thumbnails and alt text, cross-posts, community tags, and an NSFW blur gate that reveals content on request.
- Add authenticated actions for marking a post read, blocking a post author or community, and opening the vote list for a post or comment.
- Add moderation actions for posts and comments: remove, restore, lock, unlock, feature or unfeature a post in its community, and distinguish or undistinguish a comment. The controls appear only when the server reports moderation authority.
- Add community presentation for icon, banner, tags, moderator list, and notification mode. Community settings can add and remove tags and upload an icon or banner.
- Expand search to all types: posts, comments, communities, users, and URL-only post search, with cursor pagination and the existing resolved-object display.
- Add profile content tabs. Public profiles show posts and comments from `/person/content`; the signed-in profile also exposes saved, liked, read, and hidden post collections through the existing account endpoints.
- Extend v4 DTOs and requests for community tags, person actions on posts and comments, vote lists, person content, community images, and community notification modes.
- Regenerate the three Fluent catalogs and the generated Elm bindings for the new controls, menus, dialogs, and empty states.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: browsing controls, content presentation, post and comment moderation, community metadata, search types, and profile tabs.
- `lemmy-api-integration`: v4 DTO coverage and request contracts for tags, vote lists, person content, blocks, community images, and notification modes.
- `accessible-material-interface`: accessible listing controls, action menus, vote dialog, NSFW reveal, and tab navigation.

## Impact

- Frontend modules: `src/Lemmy/Domain.elm`, `src/Lemmy/Route.elm`, `src/Api.elm`, `src/Feature/Feed.elm`, `Community.elm`, `CommunityManage/*`, `Post.elm`, `Profile.elm`, `Search.elm`, `Notifications.elm`, `App/View/*`, `App/Features.elm`, and `App/State.elm`.
- Presentation: `Ui/PostCard.elm`, `Ui/CommentCard.elm`, a shared listing-control component, a vote-list dialog, and a profile tab strip.
- Localization: new Fluent keys in `translations/messages.*.ftl` and regenerated `src/Generated/I18n.elm` plus hashed JSON catalogs.
- Tests: domain decoders, route query state, browser flows for listing controls, NSFW reveal, moderation actions, vote lists, search types, profile tabs, community tags, and image uploads.
- Backend: no change. The implementation uses existing v4 routes for post and comment moderation, block, read, like lists, community tags and images, search, and person content.
