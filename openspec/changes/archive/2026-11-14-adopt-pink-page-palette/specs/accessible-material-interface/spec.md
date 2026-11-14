## MODIFIED Requirements

### Requirement: Responsive Material presentation

The interface SHALL use consistent Material Design 3 color, typography, elevation, shape, and interaction states. At 1200 CSS pixels and wider, the layout SHALL present a permanent navigation drawer, a bounded discussion column, and contextual information. Below 1200 CSS pixels, the layout SHALL present a single content column whose navigation is available through an accessible modal drawer. Source order SHALL remain meaningful across layouts and directions.

The application bar SHALL present a distinct branded surface that is visually separate from the page surface. It SHALL be a single flat color (not a gradient), SHALL remain fully opaque, and SHALL stay visible while page content scrolls beneath it. Foreground text, icons, and control boundaries inside the application bar SHALL meet the contrast thresholds in the accessibility conformance requirement against that surface.
It SHALL contain only the menu affordance and the product wordmark.

The branded palette SHALL be pink: the primary, container, on-surface, outline, focus, and application-bar tokens SHALL resolve to pink hues in both light and dark themes. The page surface (`--md-surface`) SHALL be pure white in light mode. Decorative accent color SHALL be confined to emphasis that does not carry meaning alone and SHALL NOT be used for small text on light surfaces unless it meets the text contrast threshold. The current-page state in the navigation drawer SHALL be conveyed by at least one non-color cue in addition to any color change.

#### Scenario: Compact viewport

- **WHEN** a user opens a discussion on a 320 CSS pixel viewport
- **THEN** navigation and actions remain available without page-level horizontal scrolling, except inherently two-dimensional content in its own labeled region

#### Scenario: Branded opaque application bar

- **WHEN** a reader loads any implemented page at any supported viewport
- **THEN** the application bar is visually distinct from the page surface, is a single flat color, remains fully opaque and sticky, and its menu affordance and wordmark keep at least a 4.5:1 contrast ratio against that background

#### Scenario: Wide permanent drawer

- **WHEN** a reader loads any implemented page at 1200 CSS pixels or wider
- **THEN** the navigation drawer is visible without interaction and the content column remains bounded without page-level horizontal scrolling

#### Scenario: Header focus and current-page cues

- **WHEN** a keyboard user focuses a control inside the application bar or the navigation drawer
- **THEN** the focus indicator meets at least a 3:1 contrast ratio against its surface, and the current destination is distinguishable through weight or a visible indicator as well as any color change

#### Scenario: Restrained accent on light surfaces

- **WHEN** an accent color is applied to chips, notice borders, or section labels on light surfaces
- **THEN** any small accent text still meets 4.5:1 and no meaning is conveyed by that accent color alone
