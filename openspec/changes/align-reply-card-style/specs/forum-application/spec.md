# Spec Delta

## ADDED Requirements

### Requirement: Reply cards follow the topic post card visual hierarchy
The application SHALL present reply cards with the same card surface, spacing, heading and metadata hierarchy, and action-row treatment used for topic post cards. Reply cards SHALL identify the author, community, and publication time while retaining the reply content and reply-specific actions.

#### Scenario: View a reply in a discussion
- **WHEN** a reader views a reply card in a discussion
- **THEN** its visual hierarchy matches the topic post card and its metadata identifies the author, community, and publication time

#### Scenario: Use reply actions
- **WHEN** a reader views a reply card with available reply, vote, save, edit, delete, or moderation actions
- **THEN** those actions remain available according to the existing permissions and retain their current behavior

#### Scenario: View nested replies
- **WHEN** a reply has loaded child replies
- **THEN** the card preserves the existing nested reply hierarchy and expand or collapse behavior
