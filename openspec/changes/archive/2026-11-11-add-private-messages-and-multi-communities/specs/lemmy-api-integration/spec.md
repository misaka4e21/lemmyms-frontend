## ADDED Requirements

### Requirement: Private message DTO and request coverage
The application SHALL decode the full `PrivateMessageView` with the message identifier, creator, recipient, content, published and updated timestamps, and the deleted, deleted-by-recipient, and removed flags. It SHALL read received messages from `GET /account/notification/list` with notification type `private_message` and SHALL use `POST /private_message`, `PUT /private_message`, and `DELETE /private_message` for creation, editing, and deletion. It SHALL use `POST /private_message/report` and `PUT /private_message/report/resolve` for reports. It SHALL NOT invent a sent-message list or a conversation-read endpoint.

#### Scenario: Create message request
- **WHEN** a reader sends a private message
- **THEN** the request body contains `content` and `recipient_id` and the response is decoded as a private-message view

#### Scenario: Edit and delete requests
- **WHEN** the message owner edits or deletes the message
- **THEN** the edit request contains the message identifier and content, and the delete request contains the message identifier and requested deleted state

#### Scenario: Message notification query
- **WHEN** the messages filter loads
- **THEN** the notification request contains `type_=private_message`, the current cursor, and the page limit

#### Scenario: Message report requests
- **WHEN** a recipient reports the message or an administrator resolves the report
- **THEN** the create request contains the message identifier and reason, and the resolve request contains the report identifier, resolution, and optional conclusion

### Requirement: Multi-community DTO and request coverage
The application SHALL decode `MultiCommunityView`, the multi-community detail response with its member communities, and the paginated list response. It SHALL use `GET /multi_community/list` with the supported listing type, sort, search term, creator filter, time range, and cursor. It SHALL use `GET /multi_community` by name or identifier, `POST /multi_community`, `PUT /multi_community`, `POST /multi_community/entry`, `DELETE /multi_community/entry`, and `POST /multi_community/follow`. Multi-community post feeds SHALL use `GET /post/list` with `multi_community_name`.

#### Scenario: Directory request
- **WHEN** the directory loads with a listing type, sort, and search term
- **THEN** the request carries those values and the response decodes as a paginated multi-community page

#### Scenario: Detail request
- **WHEN** `/m/:name` loads
- **THEN** the detail request uses the name and the response supplies the multi-community view and member communities

#### Scenario: Entry request
- **WHEN** the owner adds or removes a member community
- **THEN** the request contains the multi-community identifier and the community identifier

#### Scenario: Follow request
- **WHEN** the reader follows or unfollows a multi-community
- **THEN** the request contains the multi-community identifier and the requested follow boolean

#### Scenario: Multi-community feed request
- **WHEN** the detail page requests posts
- **THEN** the post request contains `multi_community_name`, the selected sort, time range, and cursor
