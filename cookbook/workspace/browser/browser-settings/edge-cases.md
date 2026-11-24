
- **Null and empty input**: An empty site data store shows an empty table in
  the Site Data window with no empty-state text (see `no-inline-help-labels`).
  An agent history access value stored by hand that is not one of the three
  choices reads as the default, None.
- **Boundary values**: A pane with no history store records nothing whatever
  "Record history" says, as today; the History help topic says so, and the
  checkbox carries no explanation (MUST, see `help-covers-regrouped-topics`).
- **Concurrent access**: Two panes may override "Agent can see history"
  differently; each reads its own layered value. Refresh pressed twice in the
  Site Data window keeps one read in flight, so an older answer never lands
  after a newer one.
- **Error states**: WebKit's site data removal reports no failure, so the
  Site Data window re-reads the store after every removal; a site still listed
  afterwards is what a failed removal looks like, and no sheet is shown.
- **Offline or disconnected state**: Not applicable — every setting here is
  local.
- **Missing file or unreachable server**: Not applicable — settings are read
  from the local settings store.
- **Cancellation and timeouts**: Closing the Site Data window abandons any read
  in flight; nothing is removed unless the user confirmed.
- **Private browsing turned on while a pane is open**: Private browsing applies
  to panes opened after the change; the recording gate reads the pane's own
  private state, so a pane opened private never records, and a pane opened
  before the change keeps the state it was made with.
- **A Chrome pane's settings sheet**: Protection and Site Data are WebKit's
  alone, so a Chrome pane's sheet leaves both groups out of Privacy and
  Security, as General leaves out AirPlay and Web Inspector; the keys keep
  their rows in the Settings window (`every-browser-key-has-a-home`).

