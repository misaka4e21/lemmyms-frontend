# Tasks

## 1. Align community forms with the API

- [x] 1.1 Remove read/post policy state, normalization, controls, and request fields from community creation; verify the form submits only supported community fields.
- [x] 1.2 Remove read/post policy state and controls from community management; verify edits preserve and submit `visibility` and `posting_restricted_to_mods`.

## 2. Show API-backed permissions

- [x] 2.1 Update community cards and detail summaries to display visibility and show a posting label only when moderator-only posting is enabled; verify labels follow the returned API fields.
- [x] 2.2 Remove obsolete `eligibleUsers` presentation usage and update localized labels for the supported rules; verify generated translations build and no obsolete label remains in community views.

## 3. Verify permission behavior

- [x] 3.1 Check creation, management, directory, and detail flows against the spec scenarios; verify no client-only policy values are sent or shown.
- [x] 3.2 Confirm personalized action controls still use returned role/action state and denied mutations remain visible as server errors; verify with the existing permission handling paths.
