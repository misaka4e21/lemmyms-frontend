## ADDED Requirements

### Requirement: Accessible browsing controls and action menus
Listing, sort, time range, and view mode controls SHALL use persistent labels and expose their selected value. Post and comment moderation actions SHALL be grouped under an accessible menu or disclosure control, SHALL use localized names, and SHALL not rely on color or icon shape alone. Menus SHALL open and close by keyboard and return focus to their trigger.

#### Scenario: Keyboard listing change
- **WHEN** a keyboard user changes the sort with the native select
- **THEN** the new value is exposed and the focused control remains usable

#### Scenario: Action menu
- **WHEN** a keyboard user opens a post action menu and chooses an action
- **THEN** the action is announced by its localized name and focus returns to the menu trigger after completion

### Requirement: Accessible vote dialog and NSFW reveal
The vote dialog SHALL have a localized name, contain focus while open, close on Escape, and restore focus to its trigger. The NSFW reveal control SHALL be a labeled button or summary that exposes the hidden state, and the hidden body SHALL not be announced as visible content before reveal.

#### Scenario: Open and close votes
- **WHEN** a moderator opens the vote dialog and presses Escape
- **THEN** the dialog closes and focus returns to the vote trigger

#### Scenario: Reveal NSFW content
- **WHEN** a reader activates the NSFW reveal control
- **THEN** the body and media become visible and the control reports the revealed state

### Requirement: Accessible profile tabs
Profile content tabs SHALL expose a tab list, tab roles, selected state, and roving keyboard focus. Activating a tab SHALL update the URL and move focus to the tab panel heading or first meaningful content without resetting the whole page.

#### Scenario: Navigate profile tabs by keyboard
- **WHEN** a keyboard user moves between profile tabs with the arrow keys and activates a tab
- **THEN** the selected tab is exposed programmatically and the matching panel is shown
