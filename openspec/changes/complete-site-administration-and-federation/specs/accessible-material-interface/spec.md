## ADDED Requirements

### Requirement: Accessible administration and federation workflows
The new setup, administration, review, and federation pages SHALL provide localized labels, keyboard-operable controls, associated validation messages, visible loading and empty states, and accessible confirmations for destructive actions. Focus SHALL move to a confirmation dialog when opened and return to its trigger when dismissed.

#### Scenario: Keyboard confirmation
- **WHEN** an administrator opens and cancels a destructive-action confirmation using the keyboard
- **THEN** no action is submitted and focus returns to the triggering control
