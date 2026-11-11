## ADDED Requirements

### Requirement: Extended v4 DTO coverage
The application SHALL decode community tags on community and post views, person actions on post and comment views, vote views from post and comment like lists, and person content as a tagged union of post and comment views. Optional fields SHALL remain absent rather than invented.

#### Scenario: Tagged community view
- **WHEN** a community or post response includes a tag list
- **THEN** decoding succeeds and the tags remain available to the view

#### Scenario: Person content item
- **WHEN** a person content response returns a post or comment item
- **THEN** the item is decoded as the matching view and unknown extra fields are ignored

### Requirement: Extended v4 action requests
The application SHALL use the existing v4 routes for post and comment removal, locking, community featuring, comment distinguishing, post read state, person and community blocks, post and comment like lists, community tag creation and deletion, community icon and banner upload, and community notification mode changes. Requests SHALL carry the identifiers and booleans required by those routes and SHALL NOT retry a failed mutation automatically.

#### Scenario: Post moderation request
- **WHEN** a moderator removes or locks a post
- **THEN** the request targets the post moderation route with the post identifier and the requested state

#### Scenario: Community image request
- **WHEN** a manager uploads a community icon or banner
- **THEN** the multipart request targets the matching community image route with the community identifier in the query

### Requirement: Extended v4 search and person content queries
Search SHALL send `type_` values for all, comments, posts, communities, and users, and SHALL use `post_url_only` for URL search. Person content SHALL send the username or person identifier with an optional content type, and both queries SHALL preserve the same `page_cursor` contract used by other v4 lists.

#### Scenario: Search type query
- **WHEN** a reader searches for comments or users
- **THEN** the request includes the matching `type_` value and the current cursor when one exists

#### Scenario: Person content query
- **WHEN** a profile tab requests comments
- **THEN** the request includes the username and `type_=comments` and replaces the list with the returned page
