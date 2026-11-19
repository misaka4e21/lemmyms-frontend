# Design

## Context

See proposal.md for motivation. Account settings, community creation and management, and site configuration currently represent `discussion_languages` as comma-separated text and parse it when building integer-array request bodies. Lemmy's site response supplies configured IDs and the supported `all_languages` catalog; the current shared site decoder does not yet expose that catalog to every form.

## Goals / Non-Goals

**Goals:**
- Make discussion language selection consistent across account, community, and site settings.
- Populate options from Lemmy's `all_languages` response data and display API-provided names with stable integer IDs.
- Store selected IDs as integer lists and preserve existing request formats.
- Preserve unknown configured IDs and drafts through unrelated edits and failed saves.

**Non-Goals:**
- Change the interface display-language selector or its translation catalogs.
- Change account, community, or site API payloads or add language management.

## Decisions

- Decode `all_languages` from the existing Lemmy v4 `GET /api/v4/site` response as a shared language catalog. Pass that catalog to language-bearing features rather than defining a static ID/name list or making duplicate per-form requests.
- Use a reusable dropdown multi-select. Activating its labeled field opens a list of checkbox options whose labels come from the API catalog; readers can select or deselect multiple languages. The field summarizes current selections when closed. Keep selection state as integer lists in each feature model; remove comma-separated parsing from these forms.
- Preserve configured IDs not present in `all_languages` as selected fallback options labeled with their IDs. A reader may explicitly deselect them, but unrelated changes must not silently discard them.
- When the site response lacks a valid catalog, keep current form data and use the existing site-load failure and retry behavior. Disable discussion language editing until valid options are available; unrelated fields retain their current save behavior where their form remains loaded.

## Risks / Trade-offs

- A custom dropdown multi-select needs consistent keyboard and screen-reader behavior → use native disclosure and checkbox semantics, persistent labels, and shared behavior across forms.
- Site responses from incompatible or incomplete servers may omit `all_languages` → report the existing site-load failure and retain drafts rather than presenting a misleading partial catalog.
- Migrating several form models can expose inconsistent defaults → add coverage for each form's loaded selections and encoded update payload.

## Migration Plan

No data migration is required. Existing server values and update payloads remain integer IDs. Rollback can restore the text fields while retaining the same API contract.
