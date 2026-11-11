## ADDED Requirements

### Requirement: Top-bar profile entry
For an authenticated reader, the application bar SHALL show a profile control that links to the reader's own profile. The drawer account destinations SHALL NOT include a Profile destination. The drawer profile header SHALL remain a display summary rather than the primary profile navigation entry.

#### Scenario: Open own profile from the top bar
- **WHEN** an authenticated reader activates the profile control in the application bar
- **THEN** the application opens the reader's own profile route

#### Scenario: Drawer has no Profile destination
- **WHEN** an authenticated reader opens the drawer
- **THEN** the account destinations contain My content, Blocks, Settings, and Log out without a duplicate Profile link

#### Scenario: Anonymous reader
- **WHEN** an anonymous reader loads a page
- **THEN** the application bar does not show an authenticated profile control

### Requirement: Local and remote profile handles
Profile links and person lookups SHALL use a single username for local people and `name@domain` for remote people. The same handle SHALL be used by author links, moderator links, search person links, profile routes, person reads, and person-content reads. The application SHALL recognize the signed-in reader's own profile when the route contains either their local username or their local `name@domain` handle.

#### Scenario: Local author link
- **WHEN** a post or comment is authored by a local person
- **THEN** its author link contains the person's single username and the person read uses that username

#### Scenario: Remote author link
- **WHEN** a post or comment is authored by a remote person
- **THEN** its author link contains `name@domain` and the person read uses that handle

#### Scenario: Own profile detection
- **WHEN** the signed-in reader opens either `/u/name` or `/u/name@host` for their own local account
- **THEN** the profile reports the own-profile tabs and does not treat it as another person

#### Scenario: Remote profile unavailable
- **WHEN** a remote profile handle cannot be resolved
- **THEN** the profile shows a localized unavailable state without rewriting the handle to a local username
