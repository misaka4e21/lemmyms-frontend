# Spec Delta

## ADDED Requirements

### Requirement: Reply cards follow the topic post card visual hierarchy
The application SHALL present reply cards with the same card surface, spacing, metadata hierarchy, content spacing, and action-row treatment used for topic post cards. Reply cards SHALL show author identity, community, and publication time in metadata, without using a large author heading; comment content SHALL remain in the regular body text.

#### Scenario: View a reply in a discussion
- **WHEN** a reader views a reply card in a discussion
- **THEN** its metadata identifies the author, community, and publication time, and the reply content appears in regular body text without a large author heading

#### Scenario: Use reply actions
- **WHEN** a reader views a reply card with available reply, vote, save, edit, delete, or moderation actions
- **THEN** those actions remain available according to the existing permissions and retain their current behavior

#### Scenario: View nested replies
- **WHEN** a reply has loaded child replies
- **THEN** the card preserves the existing nested reply hierarchy and expand or collapse behavior

#### Scenario: View comments on a profile
- **WHEN** a reader views a person's comments tab
- **THEN** each comment uses the reply metadata hierarchy without a large author heading, and activating its author link continues to open that comment in its discussion
