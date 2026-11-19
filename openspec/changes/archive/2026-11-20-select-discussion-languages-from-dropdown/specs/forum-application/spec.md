# Spec Delta

## ADDED Requirements

### Requirement: Discussion language selection in account and community forms
Account settings, community creation, and community management SHALL let readers select discussion languages from the current Lemmy language catalog using a labeled dropdown multi-select. Opening the field SHALL reveal labeled checkbox options that support selecting multiple languages; the closed field SHALL summarize current selections. The forms SHALL retain selected integer IDs and submit them in the existing `discussion_languages` array field.

#### Scenario: Edit account discussion languages
- **WHEN** an authenticated reader selects discussion languages in account settings and saves
- **THEN** the selected IDs are submitted as the existing integer array and remain selected when settings reload

#### Scenario: Create a community with discussion languages
- **WHEN** a reader selects discussion languages while creating a community
- **THEN** the selected IDs are submitted as the community's `discussion_languages` array

#### Scenario: Manage community discussion languages
- **WHEN** an authorized manager changes a community's discussion languages
- **THEN** the selected IDs are submitted as the community's `discussion_languages` array and the returned state is shown

#### Scenario: Preserve configured languages missing from the catalog
- **WHEN** an account or community contains a configured language ID absent from the current catalog
- **THEN** the selector retains that ID as a selected fallback option and unrelated edits do not remove it

#### Scenario: Language catalog is unavailable
- **WHEN** a form cannot access valid language catalog data
- **THEN** its language selector is unavailable for editing, the form preserves existing selections, and the interface offers the existing site-load retry path
