## MODIFIED Requirements

### Requirement: Navigation drawer structure

The navigation drawer SHALL be 360 CSS pixels wide where the viewport allows, SHALL begin below the application bar, and SHALL scroll its own content when that content exceeds the viewport height. It SHALL present, in order: a profile header, the primary destinations Latest, Communities, Search, and Notifications, a separator, any role-gated current-site management destination, the account destinations, and a footer containing the language selector and localization status. The drawer SHALL expose a navigation landmark named by the localized main navigation label.

Each destination SHALL render as a control at least 48 CSS pixels tall with a decorative icon and a visible localized label. The current destination SHALL show an indicator surface and at least one non-color cue. The notification destination SHALL display the unread count as a trailing badge, and its accessible name SHALL retain the full localized notification phrase including the count, including when the count is zero. When the unread count is zero, the trailing badge SHALL remain visible with a neutral surface treatment and SHALL NOT use the error color.

#### Scenario: Authenticated destinations

- **WHEN** a signed-in reader opens the drawer
- **THEN** the drawer offers the four primary destinations plus My content, Blocks, Settings, and Log out, in that order

#### Scenario: Site administrator destinations

- **WHEN** a signed-in site or deployment administrator opens the drawer
- **THEN** a current-site management destination appears after the primary separator and before account destinations

#### Scenario: Ordinary account destinations

- **WHEN** a signed-in account without administrative roles opens the drawer
- **THEN** no current-site management destination is rendered

#### Scenario: Anonymous destinations

- **WHEN** an anonymous reader opens the drawer
- **THEN** the drawer offers the four primary destinations and a Log in destination, and does not offer My content, Blocks, Settings, management, or Log out

#### Scenario: Unread notification badge

- **WHEN** the signed-in reader has unread notifications
- **THEN** the notification destination shows the count beside its label and its accessible name still contains the complete localized notification phrase

#### Scenario: Zero unread badge

- **WHEN** the signed-in reader has zero unread notifications
- **THEN** the notification destination still shows a zero badge, the badge uses a neutral surface treatment instead of the error color, and its accessible name contains the complete localized notification phrase including the zero count

#### Scenario: Active destination

- **WHEN** the reader is on a destination represented in the drawer
- **THEN** that destination carries a visible indicator and an accessible current-page state that do not depend on color alone

#### Scenario: Narrow drawer width

- **WHEN** the drawer opens on a viewport narrower than 416 CSS pixels
- **THEN** it spans the viewport minus 56 CSS pixels for the dismissing scrim and introduces no page-level horizontal scrolling

## ADDED Requirements

### Requirement: Top-bar profile control
The application bar profile control SHALL be a link or button with a localized accessible name identifying the reader's profile. It SHALL provide a target of at least 48 by 48 CSS pixels and SHALL show a decorative avatar with the display name visible where space allows. The avatar SHALL NOT replace the accessible name on compact viewports.

#### Scenario: Keyboard profile entry

- **WHEN** a keyboard user focuses and activates the top-bar profile control
- **THEN** the own profile opens and the control has a visible focus indicator and localized accessible name

#### Scenario: Compact profile entry

- **WHEN** the application bar renders at a compact width
- **THEN** the avatar remains available, the accessible name remains the localized profile label, and the control does not crowd out the menu or wordmark
