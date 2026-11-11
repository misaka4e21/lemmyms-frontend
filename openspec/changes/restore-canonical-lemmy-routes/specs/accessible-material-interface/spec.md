## MODIFIED Requirements

### Requirement: Semantic navigation and keyboard operation
Pages SHALL expose landmarks, one primary heading, meaningful heading hierarchy, a skip link, labeled native controls, and descriptive link/button names. Every action SHALL be keyboard operable with visible, unobscured focus and logical tab order. SPA navigation SHALL update the title and move focus to the new page heading; pagination and reply expansion SHALL keep focus predictable without resetting the whole page.

A discussion route with an explicit comment target SHALL move focus to the referenced comment after it loads and SHALL keep the page heading as the primary heading. If the target cannot be resolved, focus SHALL move to the localized unavailable message.

#### Scenario: Navigate by keyboard
- **WHEN** a keyboard user follows a topic link and then expands replies
- **THEN** the destination heading receives focus and expansion keeps focus on its trigger with its expanded state exposed

#### Scenario: Direct comment target
- **WHEN** a reader opens `/post/10/42` or arrives through `/comment/42`
- **THEN** focus moves to the loaded comment 42, which is exposed as a labeled article or region, and the page heading remains the single primary heading

#### Scenario: Missing comment target
- **WHEN** a direct comment target cannot be loaded
- **THEN** focus moves to the localized unavailable message and no empty comment container receives focus
