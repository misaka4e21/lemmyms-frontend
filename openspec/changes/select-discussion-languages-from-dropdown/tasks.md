# Tasks

## 1. Shared language catalog

- [x] 1.1 Decode Lemmy `GET /api/v4/site` `all_languages` into shared language ID/name data; verify valid entries decode and missing or malformed data follows site-load error handling.
- [x] 1.2 Implement a reusable accessible dropdown multi-select with labeled checkbox options and a closed-field selection summary, including selected fallback options for IDs absent from the catalog; verify options and selected IDs render correctly.

## 2. Account and community forms

- [x] 2.1 Migrate account settings discussion languages to integer-list state and the shared selector; verify loaded selections and the account update payload.
- [x] 2.2 Migrate community creation and management discussion languages to integer-list state and the shared selector; verify create and update payloads preserve selected IDs.

## 3. Site configuration

- [x] 3.1 Use the shared catalog and selector in site configuration; verify existing IDs, unknown IDs, dirty tracking, unrelated settings, and failed-save drafts are preserved.
- [x] 3.2 Update localized discussion-language labels in all supported translations; verify generated localization resources pass the repository i18n check.

## 4. Verification

- [x] 4.1 Update and run browser regressions for account settings, community creation, community management, and site configuration, including catalog failure/retry and unknown IDs; verify Elm formatting and compilation.
