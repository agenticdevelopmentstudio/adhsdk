
- **role**: The header lines are system labels and the action is a system push button; the controller sets no role or trait of its own.
- **body-identifier**: The body view MUST expose the identifier "mail.reader.body" for assistive and automated lookup.
- **button-label**: The remote-content action MUST be labeled by its visible title "Load Remote Images".
- **keyboard-path**: The "Load Remote Images" button and the selectable header text use standard system controls, so they take part in the system key view loop; the controller adds no shortcut of its own.
- **small-button-target**: NEEDS REVIEW: Not implemented in source. The button is set to small control size and the source states no minimum target size; a design decision on whether that size meets the platform minimum is needed, settled by measuring the rendered button against the Apple Human Interface Guidelines.
- **state-announcement**: NEEDS REVIEW: Not implemented in source. Nothing announces a change of open message, the hiding of the remote-content bar, or the end of the body load to assistive technology; whether the system's own announcements for the web view suffice is settled by testing with VoiceOver.

