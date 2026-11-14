
**Decision**: Authenticate on every reveal and never on hide.
**Rationale**: The source says lifting the screen takes the owner's authentication every time and hiding is always allowed.
**Approved**: pending

**Decision**: Start the shell when the pane first appears, with words read without a prompt, and show nothing.
**Rationale**: The source says the words are what conceal the shell's output, so it cannot start without them, and starting shows nothing; only words under the old user-presence guard make it wait.
**Approved**: pending

**Decision**: Put the privacy screen outside the concealed container.
**Rationale**: The source says the screen hides nothing worth hiding from a screen reader and its eye has to be reachable by one to be pressed.
**Approved**: pending

**Decision**: Hold the terminal view still while a shelf slides beside the pane.
**Rationale**: The source says resizing on every frame redraws the whole grid and resizes the shell's tty each time.
**Approved**: pending

**Decision**: Ignore pane spacing and leave the gap to the terminal's own padding.
**Rationale**: The source says the terminal insets its own grid and a theme may override that padding, so the pane pins it flush.
**Approved**: pending

**Decision**: Show an authentication failure as the screen message on reveal, but as an alert sheet when editing words.
**Rationale**: The source does it this way; the screen is the pane's only surface when the terminal is hidden, while the editor opens from a dialog that was dismissed first. A failed reveal gives no alert.
**Approved**: pending

**Decision**: Exclude the window from screen capture only while the pane is revealed.
**Rationale**: The source delegates this to the concealed container, which blanks the window while any concealed view in it is revealed and restores it afterward.
**Approved**: pending

