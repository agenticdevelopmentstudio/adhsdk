
- **two-separate-lists**: The store MUST keep the user list and the agent
  list apart: an entry belongs to exactly one list, and every query MUST
  name a list and MUST return only that list's entries, so an agent-list
  entry never appears in a user-list answer and the reverse.
- **entry-fields**: The store MUST record for every entry an identifier
  assigned by the store, its list, its site pattern, its CSS selector, its
  scope (this item, or all items like it), its label, whether it is
  enabled, and its creation time, and MUST return all of them unchanged
  when the entry is read back.
- **default-site-pattern**: Where an entry is created from a page, its site
  MUST default to the site pattern derived from that page's address by the
  shared site-pattern rules: the page's host followed by `/*`, or the
  everywhere pattern `*` for a page with no host.
- **site-wide-matching**: An entry MUST apply to a page if and only if its
  site pattern matches the page's address under the shared site-pattern
  matching rules; a page on another host MUST NOT receive it, and a page
  with no address MUST receive only entries whose site is `*`.
- **items-include-disabled**: Listing a list's items for a page MUST return
  every entry of that list whose site matches the page, enabled and
  disabled alike, so a caller can show and toggle disabled entries.
- **enabled-selectors-only-enabled**: Asking for a list's enabled selectors
  for a page MUST return the selectors of exactly the entries of that list
  that match the page and are enabled; a disabled entry's selector MUST NOT
  be returned.
- **add-returns-stored-entry**: Adding an entry MUST store it and return it
  with its newly assigned identifier, and the entry MUST be returned by
  subsequent queries for a matching page.
- **set-enabled**: Setting an entry's enabled state MUST change only that
  entry's enabled flag, leaving the entry and its other fields in place.
- **remove-entry**: Removing an entry MUST delete it, so no later query
  returns it.
- **site-switch-defaults-on**: The per-site "Hide distracting items" switch
  MUST read as on for any list and site for which it has never been set.
- **site-switch-off-empties-user-list**: While the user list's switch for a
  site is off, asking for the user list's enabled selectors for a page
  matching that site MUST return none, and the user list's entries for that
  site MUST remain stored, unchanged, so turning the switch back on
  restores them.
- **site-switch-persists**: Setting a site switch MUST be stored, so the
  value set is the value read afterwards, including after the store is
  reopened.
- **agent-list-ignores-site-switch**: The agent list MUST have no site
  switch in effect: its enabled selectors for a page MUST be returned
  whatever any switch for that site says.
- **change-notification**: Every change to stored state (adding, enabling
  or disabling, removing an entry, and setting a site switch) MUST post the
  store's change notification after the change is stored, so a page showing
  can be re-rendered.
- **persists-across-reopen**: Entries and site switches MUST survive
  closing and reopening the store's file, so a hidden-item list survives
  reloads and relaunches.
- **standalone-file**: The store MUST keep its data in its own SQLite file
  named `BrowserHiddenItems.db`, separate from every other database (not a
  migration of the project database), so the file can be deleted without
  touching anything else.
- **file-in-app-home**: The store's default file location MUST be the app's
  home directory (`~/.agenticdeveloperkitchen/BrowserHiddenItems.db`), and
  MUST follow the test home override (`APP_TEST_HOME`) when one is set.
- **opened-at-launch**: The browser feature MUST open the store once at
  launch and share that one store with every pane, in the same way the
  browser history store is opened. The open MUST run off the main thread,
  and a read of the shared store made before the open finishes MUST wait
  for it rather than answer that there is no store, so a consumer that
  fails closed on no store (the agent gatekeeper) never runs ahead of the
  open. A reader that can run during launch (an engine's first read, the
  pane's toolbar actions, an agent view's page read) MUST await the open
  rather than block the main thread on it; an open that fails MUST answer
  no store.

