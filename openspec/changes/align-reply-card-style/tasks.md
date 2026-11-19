# Tasks

## 1. Reply card structure

- [ ] 1.1 Update the reply card heading and metadata to show the author, community, and timestamp in the topic card hierarchy; verify the generated markup keeps the comment heading id and links to the correct destinations.
- [ ] 1.2 Adjust reply card content and action spacing with comment-scoped styles; verify nested replies, voting, saving, and permission-gated controls retain their behavior.

## 2. Visual verification

- [ ] 2.1 Review reply cards in a discussion, search results, and profile comments at desktop and narrow viewport widths; verify card surface, heading, metadata, content spacing, and actions align with topic cards while long labels wrap cleanly.
- [ ] 2.2 Confirm the change is confined to frontend presentation and introduces no backend or API changes by reviewing the implementation diff.
