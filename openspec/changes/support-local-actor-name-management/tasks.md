## 1. Account username editing

- [ ] 1.1 Add the current username and editable username field to account settings, submit it through user settings, and verify success refreshes the session identity while failures preserve the draft.
- [ ] 1.2 Add localized federation-aware username guidance and verify the form displays the appropriate guidance for enabled and disabled federation.

## 2. Community name management

- [ ] 2.1 Add federation-aware name guidance to community creation and verify accepted names submit through the existing create endpoint while rejected submissions preserve the form.
- [ ] 2.2 Add community name editing to community settings and verify successful rename updates the view and route while invalid or duplicate names preserve the draft.

## 3. Site administrator username changes

- [ ] 3.1 Add a username change action for users in the current-site administration list and verify it submits the selected person ID and username to the existing administrator endpoint.
- [ ] 3.2 Preserve administrator change drafts and display backend validation and authorization failures; verify unauthorized users do not receive change controls.

## 4. Verification

- [ ] 4.1 Add frontend coverage for own and administrator username changes, community creation and rename, duplicate and invalid names, and both federation states; verify the focused test suite passes.
- [ ] 4.2 Verify localized strings and accessible labels/errors for each name field, and run the project's standard frontend validation commands.
