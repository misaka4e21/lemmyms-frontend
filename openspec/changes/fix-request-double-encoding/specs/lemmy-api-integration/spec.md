# Spec Delta

## MODIFIED Requirements

### Requirement: Person lookup handle selection
The application SHALL send a local person's single username to `GET /person` and `GET /person/content`. It SHALL send `name@domain` for a remote person. The application SHALL NOT append the local hostname to a local username and SHALL NOT strip the domain from a remote handle. When resolving an actor URL for an administrator ban, the application SHALL convert a local URL to the single username and a remote URL to `name@domain`. Query encoding SHALL preserve the selected handle exactly through the API request.

#### Scenario: Local person request
- **WHEN** the application reads a local author or profile
- **THEN** the `username` query contains only the account name

#### Scenario: Remote person request
- **WHEN** the application reads a remote author or profile
- **THEN** the `username` query contains `name@domain`

#### Scenario: Local ban actor URL
- **WHEN** an administrator enters a local actor URL for a ban
- **THEN** the resolution request uses the actor's single username

#### Scenario: Percent-encoded profile route
- **WHEN** a profile route contains a percent-encoded Unicode username
- **THEN** the application decodes the route segment once and the person API receives the original username after query encoding

#### Scenario: Literal percent escapes in a profile username
- **WHEN** a profile username contains text that resembles a percent escape
- **THEN** the application preserves the literal percent text as the username rather than decoding it a second time
