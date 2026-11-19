
- A provider whose template lists no models and has no live source: the list
  shows only the current model (when there is one); the popover still opens.
- A context whose current model is empty: no row is chosen at open; the first
  row is selected for the detail pane but not chosen.
- The live list arrives after the person has chosen a row: the chosen row
  stays selected, and the arrival does not call the choice callback.
- The anchor view leaves its window while the popover is open (its settings
  panel is switched away): the popover closes.
- The person clicks outside the popover while the large-model confirmation
  is up: the confirmation is app-modal and the popover's outside-click
  dismissal is suspended, so the popover stays open until the confirmation
  is answered.
- A very long model name: the name button truncates in the middle
  (**control-name-truncates-middle**).

