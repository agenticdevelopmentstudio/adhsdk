
### Presentation

- **single-presentation-path**: The chooser MUST be presented only through
  its one entry point, which takes an anchor view, a chooser context and a
  choice callback. It MUST NOT be presented in a window of its own, and it
  MUST have no OK or Cancel button.
- **transient-popover**: The entry point MUST show the chooser in a transient
  popover pointing at the given anchor view, on the anchor's bottom edge
  (below the anchor, whichever way its coordinates run).
- **fixed-content-size**: The popover MUST open at the chooser's fixed
  content size, 720 by 450 points, not at the chooser's fitting size.
- **one-chooser-at-a-time**: Presenting the chooser while one is already shown
  MUST close the shown one first, so at most one chooser is open.
- **search-field-focus**: When the popover opens, the chooser's search field
  MUST be first responder, so typing filters the list at once.
- **opens-on-current-model**: The chooser MUST open with the row of the
  context's current model selected (a stored alias selects the row of the
  model it resolves to). Opening, and the selection the list makes for itself
  when it reloads or filters, MUST NOT choose a model.

### Choosing

- **select-chooses-and-stays-open**: A click on a row MUST choose that row's
  model at once, calling the choice callback, and MUST leave the popover
  open, so the detail pane and the choice can be compared.
- **arrow-moves-only**: An arrow key in the search field MUST move the
  selection (and the detail pane with it) without choosing; Return then
  chooses the selected row.
- **return-chooses-and-closes**: Return in the search field, or a double-click
  on a row, MUST choose the selected row's model and close the popover.
- **escape-or-outside-closes**: Escape, or a click outside the popover, MUST
  close it without choosing anything further; a model already chosen by a
  selection stays chosen.
- **chooses-only-visible-rows**: Return MUST choose nothing when the current
  filter leaves no row visible; it MUST NOT choose a row an earlier keystroke
  selected and the filter has since hidden.
- **repeat-choice-reported**: A click, Return or double-click on the row
  already chosen MUST call the choice callback again with the same value;
  the chooser does not filter repeats.
- **alias-kept-when-unchanged**: Choosing the row the context's stored model
  resolves to (a stored alias such as `fast` opens on the model it runs
  today) MUST report the stored value, not the resolved model, so the alias
  keeps following the newest model of its family.
- **large-model-confirmation**: Choosing a model whose memory fit is in the
  warn tier MUST first show one app-modal confirmation alert, with the
  popover's dismissal on outside clicks suspended until it is answered, and
  MUST call the choice callback
  only when the person confirms. Declining MUST leave the previously chosen
  model chosen and the popover open. A block-tier model MUST stay choosable
  with no confirmation; its fit line already says it will not run.
- **live-list-refresh**: The chooser MUST open on the last loaded model list
  and replace it with the provider's live list when that arrives, keeping the
  selected row (following an alias to what it now resolves to). A refresh
  MUST NOT choose a model.

### The Model Picker Control

- **control-layout**: The control MUST lay out, in one row, a label, a caret
  button, a colon and a name button: `<label> ⌄ : <model name>`.
- **control-default-label**: The label MUST default to "AI Model" and MUST be
  settable by the caller.
- **control-name-text**: The name button MUST show the name the display-name
  closure returns, and "Choose a Model" when that closure returns none or an
  empty string. When the context closure returns a context, the name MUST be
  passed through that context's display-name lookup (the context resolves an
  alias to its id and returns the display name it has for it, or the id
  unchanged when it has none); the control does no lookup of its own.
- **control-name-truncates-middle**: A name too long for the row MUST be
  truncated in the middle, so its start and end stay readable.
- **control-opens-chooser**: Clicking the caret or the name button MUST
  present the chooser through its one entry point, anchored to the caret,
  with the context the context closure returns at that moment.
- **control-forwards-choice**: Each model the chooser reports MUST be passed
  to the caller's choice closure, and the control MUST then re-read its name.
- **control-refresh**: Refreshing the control MUST re-read the name from the
  display-name closure and the enabled state from the context closure.
- **control-disabled-without-context**: The control MUST be disabled (caret
  and name both) when the context closure returns none, and clicking it then
  MUST NOT open anything.
- **control-no-globals**: The control MUST take everything it shows and does
  through its injected closures and MUST NOT read settings, a plugin manager
  or any other shared state itself.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

