
- **access-three-choices**: The agent history access setting MUST offer
  exactly three choices, in this order, with these display names: "All
  history", "Current tab only", "None".
- **access-default-none**: The setting's global default MUST be None.
- **access-setting-key**: The setting MUST be stored under the key
  `browser.agent.history_access`, and changing the global value MUST NOT
  change any other browser setting.
- **access-pane-overridable**: The setting MUST be overridable per pane
  through the pane's layered settings store, with the override marker and a
  "Use Global Setting" choice as for every other pane setting; it MUST NOT
  be a global-only setting.
- **access-row-placement**: The setting MUST appear as a pop-up row titled
  "Agent can see history" in the History group of the Privacy and Security
  settings topic.
- **effective-access-per-pane**: The tool MUST answer according to the
  effective value for the pane it is called on — the pane's override when it
  has one, otherwise the global value — read at the time of the call.
- **tool-listed**: The browser tool set MUST list a tool named
  `browser_history` with the description "Recent visits the user allows the
  agent to see: all history, this tab's back/forward list, or none
  (refused)."
- **tool-arguments**: The tool MUST accept the optional arguments `pane_id`
  (choosing the pane as the other browser tools do), `query` (a string) and
  `limit` (an integer), and MUST refuse a `query` that is not a string or a
  `limit` that is not an integer with the tool set's usual argument error.
- **limit-default-and-cap**: When `limit` is absent the tool MUST return at
  most 50 visits, and a `limit` above 200 MUST be treated as 200. (A `limit`
  below 1 is the builder's choice; see Design Decisions.)
- **none-refuses-with-reason**: When the effective access is None the tool
  MUST fail with exactly the sentence "History is not shared with the agent
  for this pane (Settings › Web Browser › Privacy and Security › Agent can
  see history)." and MUST NOT read the history store or the back/forward
  list.
- **current-tab-back-forward-only**: When the effective access is Current
  tab only, the tool MUST answer from the back/forward list of the tab the
  agent is driving in that pane, and MUST NOT read the history store.
- **current-tab-newest-first**: Current tab only results MUST be listed
  newest first, with `query`, when given, keeping only entries whose title or
  address contains it, ignoring case, and `limit` applied after filtering.
- **all-reads-store**: When the effective access is All history, the tool
  MUST answer from the history store: its recent visits, newest first, when
  no `query` is given, and its search for `query` when one is, in either case
  returning at most `limit` visits.
- **reply-lines**: Each visit in the reply MUST be one line carrying its
  title and address, and its visit time when one is known; an empty result
  MUST be a reply saying no visits were found, not a failure.
- **conceal-before-join**: Every title and every address MUST be passed
  through the pane's agent privacy concealment individually, before any of
  them is joined into the reply; nothing the tool returns MUST skip that
  path.
- **conceal-with-every-word**: Because history spans sites, the
  concealment MUST use every enabled privacy word whatever site it is
  scoped to, never only the words that apply to the page in front, combined
  with the privacy the call runs under.
- **query-matches-concealed-text**: When agent privacy is on, `query` MUST
  be matched against each visit's concealed title and address — what the
  agent would be shown — never the real text, under either access, with
  `limit` applied after that match and the newest first; otherwise whether a
  query returns visits would confirm a guess at a concealed word.
- **no-local-files**: The tool MUST NOT list a visit whose address is a
  local file (`file:`), its title or its address, under either access; under
  All history such visits MUST be left out before `limit` is applied, so the
  limit counts only listed visits.
- **conceal-url-forms**: Concealment of addresses MUST cover a privacy word
  appearing in the address in plain form, percent-escaped (a space as
  `%20`, a non-ASCII letter as its UTF-8 escapes) and form-escaped (a space
  as `+`), matching escapes of either case.
- **privacy-off-unchanged**: When agent privacy is off for the pane,
  titles and addresses MUST be returned unchanged.
- **closed-privacy-refuses**: When the pane's agent privacy is on but its
  privacy words cannot be read, or conflict — the page's words or the
  every-site words history conceals with, either side — the tool MUST fail
  with the closed-privacy refusal and return no visit.
- **same-access-checks**: The tool MUST pass the same access checks as every
  other browser tool before doing anything: a hidden or closed pane, a pane
  paused for the agent, and a closed agent privacy state each refuse as they
  do for the other tools.
- **read-only-pane-allowed**: The tool MUST be one of the read tools, so a
  pane whose agent access is read-only MUST allow it; the tool MUST never
  write, delete or reorder history.

