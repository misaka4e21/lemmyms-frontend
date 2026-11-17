## Why

The backend supports changing a local username and community name, including Chinese names when federation is disabled, but the frontend does not expose all of these operations or explain the active naming rules. Bring the profile, site user, and community management flows in line with the backend so users can manage names and understand validation failures before submitting.

## What Changes

- Add a username field to own-profile settings and a username change action to site user management.
- Add community name editing to community management and align community creation with the active naming rules.
- Show the applicable length and character guidance based on the current site's federation setting, and present backend validation and duplicate-name errors in the relevant form.
- Cover successful changes, invalid names, duplicate names, permission failures, and both federation settings in frontend tests.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `forum-application`: Specify own username editing, community name editing, and federation-aware local actor name validation in the frontend.
- `site-administration`: Specify site administrator username changes through the user management interface.

## Impact

- Affects Elm account settings, community creation and management, and site user management views and update flows.
- Uses the existing v4 endpoints for user settings, administrator username changes, community creation, and community updates; no backend API change is planned.
- Adds or updates localized guidance and form error handling, plus frontend tests for the affected flows.
