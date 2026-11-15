## ADDED Requirements

### Requirement: Administration and federation v4 transport
The application SHALL use the current LemmyMultisite v4 request and response contracts for site creation and update, registration applications, pending follows, federated instances, object resolution, OAuth authentication and provider management, taglines, emoji, user and media inventories, federation policy, administrator assignment, and supported purges. It SHALL preserve optional field semantics and backend pagination, send the current tenant's session, and surface backend errors without inventing successful results.

#### Scenario: Cursor-based administration list
- **WHEN** a supported list returns a next cursor
- **THEN** the next request sends that cursor using the endpoint's documented field

#### Scenario: OAuth authentication
- **WHEN** a validated callback is exchanged
- **THEN** the request includes the provider identifier, authorization code, and original redirect URI using the v4 contract
