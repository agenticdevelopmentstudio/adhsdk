
- **Role**: The bar is a toolbar named "Editing actions" (from Button Bar); the gone and save-failed lines have the alert role; the conflict warning is an Alert, which has the alert role.
- **Label**: The buttons are labeled by their visible text: Cancel, Save (or Saving…), Reload theirs, Overwrite.
- **State announcements**: Because the error lines and the conflict warning carry the alert role, they are announced when they appear. The changed-elsewhere notice is a plain paragraph with no role and is not announced when it appears; the source states no reason, so whether it should be announced is open.
- **Keyboard**: All controls are native buttons reachable by Tab and activated with Enter or Space; the component adds no key handling.
- **Minimum tap target**: Cancel, Save and both warning buttons use the shared Button at `size="sm"`, which is `h-7` (28px tall) with a minimum height and width that default to 0 unless an ancestor sets `--adh-button-min-height` and `--adh-button-min-width`; the component sets neither.
- **changed-notice-announcement**: NEEDS REVIEW: Not implemented in source. The changed-elsewhere notice has no alert or status role while the gone, save-failed and conflict notices do; a decision from the design owner, checked against screen-reader behavior, would settle whether it needs a live-region role.
- **orange-text-contrast**: NEEDS REVIEW: Not implemented in source. The changed notice uses `text-apt-orange` at 14px and the source does not state its contrast against the page background; a token-pair contrast measurement in light and dark themes would settle whether it meets WCAG 1.4.3.

