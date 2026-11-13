
- **footer-accessibility-prefix**: The footer MUST be given the accessibility prefix `integrations.add-remove` so its buttons have stable accessibility identifiers.
- **refusal-announcement**: When the remove button is pressed with nothing to remove, the panel MUST announce the refusal through the shared refusal feedback.
- **keyboard-confirmation**: The removal confirmation MUST be operable by keyboard: Return activates Cancel and Esc declines.
- **native-controls**: The add menu MUST be a standard menu so the platform supplies its keyboard and assistive-technology behavior.
- **tooltips-as-labels**: The add and remove buttons carry tooltips that describe their action.
- **symbol-descriptions**: NEEDS REVIEW: Not implemented in source. Both symbol images are created with no accessibility description, so what assistive technology announces for the sidebar icon and the Gmail row icon is whatever the shared panel base class composes; a VoiceOver pass over the sidebar would settle whether the row reads as "Gmail" alone.
- **footer-labels**: NEEDS REVIEW: Not implemented in source. The panel sets only tooltips on the add and remove buttons and no accessibility label; whether the shared footer view labels them for assistive technology is outside this file, and inspecting that view or a VoiceOver pass would settle it.
- **target-size**: NEEDS REVIEW: Not implemented in source. The footer button sizes belong to the shared footer and are not set here, so whether they meet the platform's minimum target size cannot be decided from this file; measuring the shared footer would settle it.

