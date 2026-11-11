## ADDED Requirements

### Requirement: Person lookup handle selection
The application SHALL send a local person's single username to `GET /person` and `GET /person/content`. It SHALL send `name@domain` for a remote person. The application SHALL NOT append the local hostname to a local username and SHALL NOT strip the domain from a remote handle. When resolving an actor URL for an administrator ban, the application SHALL convert a local URL to the single username and a remote URL to `name@domain`.

#### Scenario: Local person request
- **WHEN** the application reads a local author or profile
- **THEN** the `username` query contains only the account name

#### Scenario: Remote person request
- **WHEN** the application reads a remote author or profile
- **THEN** the `username` query contains `name@domain`

#### Scenario: Local ban actor URL
- **WHEN** an administrator enters a local actor URL for a ban
- **THEN** the resolution request uses the actor's single username
