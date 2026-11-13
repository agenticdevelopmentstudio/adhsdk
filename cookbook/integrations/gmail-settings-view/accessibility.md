
- **native-controls**: The view MUST be built from standard text fields, a secure field, buttons, toggles, pickers, a list and a progress indicator so that the platform supplies their roles, keyboard handling and focus behavior.
- **control-labels**: Every toggle and picker MUST carry its visible title as its label, and every button MUST carry its visible title.
- **status-by-text**: Account status MUST be conveyed by the badge's text, never by color alone.
- **keyboard-reach**: The view adds no custom key handling; keyboard operation depends on the standard controls.
- **row-accessibility-label**: NEEDS REVIEW: Not implemented in source. The account row is a stack of three texts with no explicit accessibility label or grouping, so what a screen reader announces for a row is whatever the platform composes; a VoiceOver pass over the list would settle whether email, status and last-synced time read as one coherent item.
- **badge-contrast**: NEEDS REVIEW: Not implemented in source. The status badge is caption text on a quaternary-style capsule and the hint captions use the secondary style; the source cannot say whether these meet 4.5:1 contrast in every appearance, and a contrast measurement in light and dark appearances would settle it.
- **spinner-announcement**: The view adds no explicit announcement for the sign-in spinner and its caption; the standard progress indicator and text supply whatever the platform exposes for them.

