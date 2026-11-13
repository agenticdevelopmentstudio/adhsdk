
- **role**: The controller exposes the system split view and system alert; it sets no role, trait or label of its own.
- **alert-label**: The alert MUST present its text as the standard alert message and informative text, and its single button MUST be titled "OK".
- **keyboard-path**: NEEDS REVIEW: Not implemented in source. The controller sets no key view loop or pane-switching shortcut, so the keyboard path between the three panes is whatever the system split view and pane controllers provide; a keyboard walkthrough of the assembled window, or a read of the three pane controllers, would settle it.
- **pane-labels**: NEEDS REVIEW: Not implemented in source. No accessibility label is set on any of the three panes by this controller; VoiceOver testing of the assembled window would show whether the pane controllers label themselves.
- **target-size**: Not applicable: the controller has no controls of its own; the alert's button is system-drawn.

