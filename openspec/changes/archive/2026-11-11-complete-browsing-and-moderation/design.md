## Context

The v4 API already exposes the data and mutations needed for this change. The client currently drops community tags, person actions, image details, cross-posts, and vote lists during decoding, and it has no shared control surface for listing state. Post and comment cards expose only reader actions. Community settings edit text fields but not tags or images. Search and profile views have a single fixed result shape. See `proposal.md` for motivation.

## Goals / Non-Goals

**Goals:**

- Keep browsing choices in the URL and send only supported v4 filters.
- Present the existing v4 post, comment, community, and profile data without inventing fields.
- Gate every moderation control on the server-reported authority.
- Reuse one presentation component for listing controls, one action menu pattern, and one vote dialog.
- Keep all new strings localized and keyboard operable.

**Non-Goals:**

- Adding multi-community, private-message, or site-administration features.
- Implementing a reason prompt for every moderation action. Remove, lock, feature, and distinguish actions send an empty reason; warning actions are out of scope.
- Persisting listing mode to the account settings instead of the URL.

## Decisions

### URL-backed listing state

A shared `Ui.ListingControls` component renders native selects for listing type, post sort, time range, and post listing mode. The URL carries `type`, `sort`, `time_range`, and `view`. `Lemmy.Route` gains helpers that replace one parameter and drop `page_cursor`, so changing a control starts a new cursor sequence. Supported listing types are `all`, `local`, `subscribed`, `moderator_view`, and `suggested`; supported sorts are the v4 `PostSortType` values. Time ranges use seconds, with an empty value meaning no override.

The post listing mode is presentation-only. `view=list`, `view=card`, and `view=small_card` change the `Ui.PostCard` layout and do not add an API parameter. The default is `card` to preserve the current card presentation.

### Post presentation

`Ui.PostCard` takes the selected mode and a `blurNsfw` flag. `card` and `small_card` display the returned `thumbnail_url` with `alt_text`; `list` stays text-first. Community tags render as chips from `PostView.tags`. A post with `nsfw` and blur enabled wraps its body and media in a native `details` element whose summary is the localized NSFW reveal control, so the closed content is not exposed as visible text.

Cross-posts come only from the post detail response. `Feature.Post` decodes `cross_posts` alongside `post_view` and renders them as links after the post body.

### Action menus and immediate mutations

`Ui.PostCard` and `Ui.CommentCard` use a native `details` disclosure for secondary actions. Reader actions remain visible. Moderation actions appear only when `can_mod` is true; block actions appear only for authenticated viewers and not for their own content. Each action sends its v4 mutation with the current boolean state inverted, and a successful response refreshes the visible representation from the returned view or reloads the route when the response has no view.

Remove, lock, feature, and distinguish send an empty reason. Warnings, mod-edit forms, and administrator-only purge actions are not part of this change.

### Vote dialog

`Feature.Post` owns one vote dialog state with a target type and a `Remote (Domain.Page Domain.VoteView)`. Opening it requests `/post/like/list?post_id=` or `/comment/like/list?comment_id=` with a limit. The dialog lists voter identity, banned state, and upvote or downvote direction. Escape and the close button restore focus to the trigger.

### Community metadata

`CommunityView` and `PostView` decode `tags` as a JSON array. `Feature.Community` decodes the full `communityResponse`, stores moderators, and renders icon, banner, tags, moderator list, and notification mode. Notification mode changes use `PUT /community/notifications` and reload the community view.

`Feature.CommunityManage` adds a tag editor and icon/banner file inputs. Tag creation and deletion use `POST /community/tag` and `DELETE /community/tag` with the community identifier. Image uploads use a new `Api.uploadTo` helper that posts multipart data to `/community/icon?id=` or `/community/banner?id=`. Every successful write reloads the management community so the server remains the source of truth.

### Search union

`Feature.Search` keeps the selected kind in the URL and maps it to `type_`. `all`, `comments`, `posts`, `communities`, and `users` map directly. `url` maps to `type_=posts` with `post_url_only=true`. Results render a resolved object first, then the returned lists. Cursor navigation reuses the existing search URL builder and preserves the kind and query.

### Profile tabs

The profile route keeps the username and adds a `view` query. Public profiles support `posts` and `comments` through `/person/content?username=&type_=`. A signed-in reader's own profile also supports `saved`, `liked`, `read`, and `hidden` through the existing account endpoints. The tab strip is a native tab list. Each tab owns its own cursor and empty or forbidden state.

## Risks / Trade-offs

- **More query state can drift from the request** → Build both from the same parsed values and cover the URL round trip in route tests.
- **Moderation actions without a reason prompt** → The API accepts an empty reason. The UI labels each action by state and refreshes from the server; warnings and reason authoring remain a later change.
- **Tags and person actions add optional decoding surface** → Treat both as optional arrays and values, and add fixtures with and without them.
- **Profile tabs combine two response shapes** → Keep a tagged content union so post pages and comment pages cannot be decoded into each other.
- **Community image upload adds multipart state** → Reuse the existing upload error handling and reload management state after success; do not insert a local URL before the server returns one.

## Migration Plan

1. Extend domain decoders and route query helpers.
2. Add listing controls and post presentation.
3. Add action menus, moderation mutations, blocks, read state, and the vote dialog.
4. Add community tags, moderators, notifications, and image uploads.
5. Add search types and profile tabs.
6. Add the Fluent keys, regenerate catalogs, and update browser tests.
7. Roll back by reverting the change commit. No database or backend migration is involved.
