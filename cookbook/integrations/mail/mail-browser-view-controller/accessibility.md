
- **role**: The controller exposes the system split view and system alert; it sets no role, trait or label of its own.
- **alert-label**: The alert MUST present its text as the standard alert message and informative text, and its single button MUST be titled "OK".
- **keyboard-path**: NEEDS REVIEW: Not implemented in source. The controller sets no key view loop and no shortcut for moving between the three panes, and relies on whatever the system split view and pane controllers provide; a keyboard run-through with VoiceOver on would settle whether a SHOULD requirement for pane switching is needed.
- **pane-labels**: The controller sets no accessibility label on the panes. Each pane controller sets its own accessibility identifier on its main view (`mail.sidebar`, `mail.messages`, `mail.reader.body`), and the sidebar and list rows set their own labels.
- **target-size**: Not applicable: the controller has no controls of its own; the alert's button is system-drawn.

