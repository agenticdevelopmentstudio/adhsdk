
- **footer-accessibility-prefix**: The footer MUST be given the accessibility prefix `integrations.add-remove` so its buttons have stable accessibility identifiers.
- **refusal-announcement**: When the remove button is pressed with nothing to remove, the panel MUST announce the refusal through the shared refusal feedback.
- **keyboard-confirmation**: The removal confirmation MUST be operable by keyboard: Return activates Cancel and Esc declines.
- **native-controls**: The add menu MUST be a standard menu so the platform supplies its keyboard and assistive-technology behavior.
- **tooltips-as-labels**: The add and remove buttons SHOULD carry tooltips that describe their action, as the panel sets.
- **symbol-descriptions**: Both symbol images SHOULD carry an accessibility description. NEEDS REVIEW: Not implemented in source. Both symbol images are created with no accessibility description, so what assistive technology announces for the sidebar icon and the Gmail row icon is whatever the shared panel base class composes; a VoiceOver pass over the sidebar would settle whether the row reads as "Gmail" alone.
- **footer-labels**: The footer's add and remove buttons MUST carry accessibility labels "Add" and "Remove", which the shared `AddRemoveFooterView` gives their symbol images, and the identifiers `integrations.add-remove.add` and `integrations.add-remove.remove`; the panel adds only the tooltips.
- **target-size**: The panel MAY leave control sizing to the shared footer, as it does: it sets no control size, and the footer buttons come from the shared settings-panel footer, which owns their size.

