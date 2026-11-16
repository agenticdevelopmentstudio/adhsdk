
- **empty-filter-lists-recent**: The list model MUST, when its filter is
  empty, list the store's most recent visits, newest first.
- **filter-searches-title-and-address**: The list model MUST, when its
  filter is not empty, list exactly the visits whose title or address
  contains the filter text, newest first.
- **filter-is-trimmed**: The list model MUST trim leading and trailing
  whitespace from the filter before using it, so a filter with surrounding
  spaces lists the same visits as the bare text, and a filter of only
  whitespace lists recent visits as an empty filter does.
- **list-is-bounded-by-page-size**: The list model MUST list at most its
  page size of visits for both recent and filtered results; the page size
  defaults to 200 and is set when the model is created.
- **latest-filter-wins**: The list model MUST coalesce reloads so that when
  the filter changes again before an earlier reload has answered, the
  visits it ends up listing are those for the latest filter, and an earlier
  filter's answer MUST NOT replace a later one's.
- **remove-deletes-from-store**: The list model MUST, when asked to remove
  a set of visits, delete each of them from the store and then reload, so
  the removed visits are gone from both the store and the list.
- **clear-all-empties-store**: The list model MUST, when asked to clear
  all, delete every visit from the store and then reload, leaving the list
  empty.
- **change-is-announced**: The list model MUST notify its observer each
  time the visits it lists change, after reloading, removing or clearing.
- **reloads-on-store-change**: The list model MUST reload whenever its
  history store announces a successful write (a pane recording a visit,
  another list removing or clearing), so a visit recorded while the panel
  is open appears; the store MUST announce every write that succeeded. The
  panel MUST also reload each time it appears, so its times are current.
- **store-work-off-ui-thread**: The list model MUST perform every store
  read and write off the UI thread and publish the resulting visits on the
  UI thread, so a slow store never blocks the interface.
- **panel-filter-drives-model**: The History panel MUST show a filter field
  with the placeholder "Filter History" above its list, and MUST set the
  list model's filter to the field's text as the user types, without
  waiting for Return.
- **panel-rows-show-visit**: The History panel MUST show one row per listed
  visit, in the model's order, each showing the visit's title, its address,
  and when it happened as a relative time.
- **panel-sidebar-list-style**: The History panel MUST present its filter
  field and list in the style of the Settings sidebar: a search field over
  a source-style list.
- **panel-remove-selected**: The History panel MUST provide a remove
  button, with the tooltip "Remove Selected Visits", that asks the list
  model to remove the visits selected in the list.
- **panel-clear-confirms**: The History panel MUST provide a Clear
  History… button, with the tooltip "Clear All History", that asks for
  confirmation before anything is removed; it MUST ask the list model to
  clear all only when the user confirms, and MUST remove nothing when the
  user cancels.
- **panel-opens-visit**: The History panel MUST, on Return, pass the
  address of every selected visit, in list order, to the open callback its
  host supplied; on a double-click of a selected row it MUST do the same,
  and on a double-click of a row outside the selection it MUST pass that
  row's visit alone. It MUST do nothing else to open them.
- **panel-every-button-has-tooltip**: The History panel MUST give every
  button it shows a tooltip.
- **panel-no-inline-help**: The History panel MUST NOT show inline help or
  empty-state text; an empty list (no history, or nothing matching the
  filter) MUST show as an empty list.
- **panel-independent-of-host**: The History panel MUST depend only on the
  list model and the open callback it is given, and MUST NOT reference the
  History window, a shelf, or any other host, so it can be embedded by any
  host.
- **window-hosts-panel-in-shelf**: The History window MUST host the History
  panel inside a shelf shaped like the projects window's: a bar of panel
  buttons across the top holding one button, "History", with the History
  panel beneath it as the shown panel.
- **window-is-single**: The History window MUST be a single window with a
  fixed window identifier: showing it while it is already open MUST bring
  that window up rather than create a second, and it MUST save and restore
  its frame and visibility under that identifier as the app's other single
  windows do.
- **window-opened-from-browser-menu**: The Browser menu's Show History
  command MUST show the History window, and MUST stay enabled whether or
  not the key window has a browser pane, while the host has given the
  window a history store; with none it MUST be disabled.
- **window-opens-visit-in-browser**: The History window MUST open a visit
  the panel hands it in the focused browser pane of the frontmost other
  window (the window that was key before the History window) as a new tab
  when such a pane exists, and in a new browser window when none does.
- **recording-gated-on-setting**: The browser MUST record a visit only
  when the Record history setting is on and the pane is not in private
  browsing.
- **private-browsing-never-records**: The browser MUST NOT record any visit
  while a pane is in private browsing, even when the Record history setting
  is on, so no visit made in private browsing ever reaches the store or
  this panel.

