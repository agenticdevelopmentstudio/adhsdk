
- **Decision**: Show the chooser in a transient popover pointing at the
  control's caret, with no OK or Cancel button, instead of an app-modal
  window.
  **Rationale**: A modal window took the whole app for a one-field choice and
  hid the setting it changed; a popover keeps the row in view and closes on
  Escape or a click outside, the platform's own way to dismiss a picker.
  **Approved**: pending
- **Decision**: A click on a row chooses at once and the popover stays open;
  Return or a double-click chooses and closes.
  **Rationale**: The detail pane is how models are compared, so choosing must
  not end the comparison; with every click applied, there is nothing left for
  an OK button to confirm.
  **Approved**: pending
- **Decision**: The control is the chooser's only anchor in settings, and it
  takes closures rather than settings.
  **Rationale**: One control means one way to choose a model everywhere a
  provider is configured, and closures let the AI Providers panel, the
  combined provider-and-model control and the chat window bind it to their
  own settings without the control knowing any of them.
  **Approved**: pending
- **Decision**: Keep the stored alias when the person chooses the row it
  resolves to.
  **Rationale**: An alias follows the newest model of its family; replacing
  it with today's resolved id whenever the person merely looked would pin the
  configuration without their asking.
  **Approved**: pending

