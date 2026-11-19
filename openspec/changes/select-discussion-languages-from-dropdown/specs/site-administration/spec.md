# Spec Delta

## MODIFIED Requirements

### Requirement: Current site configuration workspace
The administrator workspace SHALL provide supported current-site settings including identity, description, legal text, registration, federation, content policy, languages, rate limits, and site media. It SHALL initialize fields from server data, preserve untouched fields and edits on failure, validate inputs, and reload current site state after success. Discussion languages SHALL be selected from a labeled dropdown multi-select populated by the current site's supported language catalog rather than entered as numeric IDs. Opening the field SHALL reveal labeled checkbox options that support selecting multiple languages; the closed field SHALL summarize current selections. Existing vote settings, reports, moderation log, and bans SHALL remain available.

#### Scenario: Update site settings
- **WHEN** an administrator edits a supported setting and saves it
- **THEN** the application sends the corresponding v4 site update and displays the returned current-site state

#### Scenario: Denied site update
- **WHEN** the backend rejects an update
- **THEN** the application retains the draft and displays the failure

#### Scenario: Select site discussion languages
- **WHEN** the supported language catalog is loaded and an administrator opens the dropdown and selects one or more checkbox options
- **THEN** the selected languages are shown as selected and saved as their corresponding integer language IDs

#### Scenario: Preserve configured site discussion languages
- **WHEN** site configuration loads with discussion language IDs
- **THEN** matching catalog languages appear selected, IDs missing from the catalog remain selected as fallback options, and saving unrelated settings does not remove them

#### Scenario: Language catalog is unavailable
- **WHEN** the site response omits or contains invalid supported language catalog data
- **THEN** the interface reports the localized site-load failure, does not present an incomplete selector as ready, and allows retrying the site load
