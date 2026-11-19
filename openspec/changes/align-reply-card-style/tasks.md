# Tasks

## 1. Reply card structure

- [x] 1.1 Remove the large author heading and place author, community, and timestamp in the topic-style metadata row for discussion and profile comment cards; verify existing author and community link destinations and remove stale heading references.
- [x] 1.2 Keep reply Markdown in regular body text and tune comment content/action spacing after removing the heading; verify nested replies, voting, saving, moderation controls, and profile comment links remain intact.

## 2. Visual verification

- [x] 2.1 Review reply cards in a discussion, search results, and profile comments at desktop and narrow viewport widths; verify card surface, metadata, body text, content spacing, and actions align with topic cards while long labels wrap cleanly.
- [x] 2.2 Confirm the change is confined to frontend presentation and introduces no backend or API changes by reviewing the implementation diff.
