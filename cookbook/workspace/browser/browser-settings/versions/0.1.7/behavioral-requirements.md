
- **topic-order**: The browser settings container MUST list its topics in
  exactly this order: General, Behavior, Appearance, Privacy and Security,
  Downloads, Extensions, then the Chrome engine's topics when that engine is
  compiled in, then Reset.
- **removed-topics**: The browser settings container MUST NOT list a topic
  titled "History", "Cookies", "Media and Permissions" or "Safari".
- **keys-never-change**: The browser settings container MUST bind every control
  that moves to a new topic to the same setting key it used before the move;
  only its topic and group change. A new key MUST start with `browser.`.
- **general-topic-contents**: The General topic MUST hold the custom user agent
  field, a Media group with "Allow AirPlay", and a Web Inspector group with
  "Allow Web Inspector", and nothing else.
- **behavior-topic-contents**: The Behavior topic MUST hold, in this order,
  "Open sites in tabs", "Enable JavaScript", "Block pop-up windows", the home
  page address, and a Playback group with "Autoplay".
- **open-sites-in-tabs-rename**: The control that makes File › New over a web
  browser window open a tab MUST be titled "Open sites in tabs" (it was
  "“New” opens tabs") and MUST keep the key `browser.new_opens_tabs`.
- **open-sites-in-tabs-app-only**: The Behavior topic MUST show "Open sites in
  tabs" only in the app's Settings window, never in a pane's settings sheet, because it governs a
  window's New command, not a pane.
- **appearance-topic-contents**: The Appearance topic MUST hold "Zoom",
  "Minimum font size" and the browser pane's tab position override row.
- **privacy-security-title**: The topic that was titled "Privacy" MUST be
  titled "Privacy and Security".
- **privacy-security-existing-groups-first**: The Privacy and Security topic
  MUST keep its existing groups (General, Input, Focus and visibility, Coding
  Partner, Agent Privacy, Storage, Scripts) in their existing order, before any
  group added by this ingredient.
- **privacy-security-added-groups**: The Privacy and Security topic MUST hold,
  after its existing groups, in this order, a Cookies group ("Accept cookies",
  "Private browsing"), a Camera and Microphone group ("When a page asks"), a
  Protection group ("Warn about fraudulent websites", "Upgrade known sites to
  HTTPS", "Lockdown Mode"), a Site Data group, and a History group.
- **manage-site-data-button**: The Site Data group MUST hold a single "Manage
  Site Data…" button, with identifier `settings.browser.site-data.manage`, and
  MUST NOT show the site data table inline.
- **site-data-window**: The Manage Site Data… button MUST open a window titled "Site
  Data — <jar>", where <jar> names the jar it acts on ("Shared by all browser
  panes", "Shared within this worktree", "This pane only", or private
  browsing), that is modal to the application, resizable and movable by the
  user, and holds the site data table (columns Site and Data) with a remove (−)
  control, "Remove All…", "Refresh" and "Done". Remove All…'s confirmation MUST
  name the same jar.
- **site-data-window-scope**: The Site Data window MUST, in the app's Settings
  window, list the global jar's site data; in a pane's settings sheet it MUST list
  the site data of the jar the sheet's Storage (and Private browsing) setting
  names when the button is pressed — the store that pane's page uses while the
  setting is unchanged, and the jar it names after a change made in the same
  sheet, never the jar the sheet opened on.
- **history-group-contents**: The History group MUST hold "Record history",
  "Keep visits for" and "Agent can see history", in that order; "Keep visits
  for" MUST appear only in the app's Settings window, since the visit store is
  one for the whole app.
- **history-recording-gate**: The history recording gate MUST let a browser pane
  record a visit only when
  recording is on (`browser.records_history`) and private browsing is off for
  that pane; every visit the pane records MUST pass through this one gate.
- **agent-history-access-choices**: The "Agent can see history" row MUST offer exactly
  three choices, "All history", "Current tab only" and "None", stored under the
  key `browser.agent.history_access`, and MUST default to "None".
- **agent-history-access-pane-override**: The "Agent can see history" row MUST be
  overridable per browser pane through the pane's layered settings, showing the
  override marker and "Use Global Setting" as every pane-overridable row does;
  its key MUST NOT be global-only.
- **agent-history-access-gates-tool**: The effective value of "Agent can see
  history" for the pane an agent is driving MUST be the value that decides what
  the agent's history tool may return; with "None" the tool MUST be refused.
- **keywords-follow-controls**: The browser settings container MUST give each
  topic search keywords that include the title of every control it holds, so a control that moved is found by sidebar
  search under its new topic.
- **container-keywords-union**: The container's search keywords MUST be the
  union of the keywords of every topic it lists, available before any topic
  has been opened.
- **every-browser-key-has-a-home**: The browser settings container MUST show
  every key in the browser settings key list by a row in some topic it lists; a key belonging to
  an engine whose topics are compiled out MUST be shown by that engine's
  topics when they are compiled in.
- **downloads-and-reset-unchanged**: The Downloads and Reset topics MUST keep
  their existing contents.
- **buttons-have-tooltips**: The browser settings container MUST give every
  button this ingredient adds or moves ("Manage Site Data…", the Site Data window's
  −, "Remove All…", "Refresh", "Done") a tooltip.
- **no-inline-help-labels**: The topics MUST NOT add explanatory or empty-state
  text to their views for the moved or new controls; explanation of what a
  control does MUST go in the topic's help content.
- **toolbar-buttons-have-tooltips**: A browser pane MUST give every button in
  its toolbar rows (the address row, the privacy toolbar, the tab strip's
  new-tab and close buttons, and a Safari pane's extension buttons) a
  non-empty tooltip that names the button's action ("Reload Page"), not its
  symbol; an extension's button with no label of its own MUST fall back to
  the extension's name, then to a generic action name.
- **help-covers-regrouped-topics**: The Behavior, Appearance and Privacy and
  Security topics MUST each have help content with one topic per group they
  show in that scope. A topic for a group the scope does not show MUST be
  left out, unless it is a "where to find it" topic for a control only
  another scope shows, which MUST name where that control lives (the
  Settings window's Tab Position topic names the pane's settings sheet); the
  History help MUST say that the visits are seen and cleared from Browser ▸
  Show History, and, when the app or pane has no history store, MUST say
  that nothing is recorded whatever "Record history" says (the History group
  MUST NOT say it under the checkbox); "Agent can see history" MUST have a
  help topic of its own.

