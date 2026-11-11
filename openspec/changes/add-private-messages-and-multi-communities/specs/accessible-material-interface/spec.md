## ADDED Requirements

### Requirement: Accessible private message composer and entries
The private-message composer SHALL use persistent labels for the recipient and message body, associate errors with their fields, and preserve the draft after a failed send. Message entries SHALL be articles with a heading that links to the author, a machine-readable timestamp, and actions with localized accessible names. The messages filter SHALL expose its selected state without relying on color. Deleted or removed messages SHALL not announce their hidden content, and the report dialog SHALL return focus to the control that opened it.

#### Scenario: Compose with a keyboard
- **WHEN** a keyboard user opens the composer, enters content, and submits
- **THEN** every field has a persistent label, the send control has a localized name, and failure messages are announced

#### Scenario: Message actions
- **WHEN** a screen reader inspects a received message
- **THEN** the author heading, timestamp, content, and available reply, delete, report, or mark-read actions are exposed with distinct names

#### Scenario: Deleted message
- **WHEN** a message is deleted for the viewer or removed by a moderator
- **THEN** the entry shows a localized deleted or removed state and does not expose the hidden body as readable content

#### Scenario: Filter state
- **WHEN** a reader switches between all notifications and messages
- **THEN** the active filter exposes its selected state and the message list updates

### Requirement: Accessible multi-community directory and forms
The multi-community directory SHALL provide labeled listing, sort, and search controls and headings for each result. Creation and settings forms SHALL use persistent labels, grouped fields, associated errors, and an error summary for multiple failures. The member-community picker SHALL expose search results as selectable items with localized names, and follow or entry-limit failures SHALL be announced without losing the current form values.

#### Scenario: Directory controls
- **WHEN** a keyboard user changes the listing type, sort, or search text
- **THEN** each control keeps a visible label and the result focus remains in the page

#### Scenario: Settings validation
- **WHEN** the settings form has multiple invalid fields
- **THEN** an error summary links to the fields, each field exposes its error, and the unsaved values remain

#### Scenario: Community entry picker
- **WHEN** the owner searches for a community to add
- **THEN** results expose their names and selection state and the add action has a localized name

#### Scenario: Entry limit
- **WHEN** adding a community exceeds the 50-entry limit
- **THEN** the limit failure is announced and the current member list and form stay usable

#### Scenario: Follow feedback
- **WHEN** a reader follows or unfollows a multi-community
- **THEN** the control exposes the resulting state and announces a pending remote follow without claiming membership
