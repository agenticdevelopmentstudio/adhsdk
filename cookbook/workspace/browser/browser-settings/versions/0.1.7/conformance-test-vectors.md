
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| browser-settings-001 | topic-order | Open the browser settings with the Chrome engine compiled out | Topic titles are General, Behavior, Appearance, Privacy and Security, Downloads, Extensions, Reset |
| browser-settings-002 | removed-topics | Same container | No topic titled History, Cookies, Media and Permissions or Safari |
| browser-settings-003 | keys-never-change, open-sites-in-tabs-rename | Turn on "Open sites in tabs" in Behavior | `browser.new_opens_tabs` reads true; no other key changed |
| browser-settings-004 | keys-never-change | Set Autoplay in Behavior to Never; set Zoom in Appearance to 150% | `browser.autoplay` and `browser.page_zoom` hold the new values |
| browser-settings-005 | general-topic-contents | Open General | Rows: custom user agent, Allow AirPlay, Allow Web Inspector; nothing else |
| browser-settings-006 | behavior-topic-contents | Open Behavior in the Settings window | Rows in order: Open sites in tabs, Enable JavaScript, Block pop-up windows, home page address, Autoplay |
| browser-settings-007 | open-sites-in-tabs-app-only | Open Behavior in a pane's settings sheet | No "Open sites in tabs" row |
| browser-settings-008 | appearance-topic-contents | Open Appearance | Rows: Zoom, Minimum font size, tab position override |
| browser-settings-009 | privacy-security-title, privacy-security-existing-groups-first | Open Privacy and Security | Topic title "Privacy and Security"; first groups are General, Input, Focus and visibility, Coding Partner, Agent Privacy, Storage, Scripts |
| browser-settings-010 | privacy-security-added-groups | Same topic | Groups after Scripts, in order: Cookies, Camera and Microphone, Protection, Site Data, History |
| browser-settings-011 | manage-site-data-button | Open the Site Data group | One button "Manage Site Data…", id `settings.browser.site-data.manage`; no table in the topic |
| browser-settings-012 | site-data-window | Press Manage Site Data… | A window titled "Site Data — <jar>" opens, naming the jar, app-modal, resizable, movable, with columns Site and Data and −, Remove All…, Refresh, Done |
| browser-settings-013 | site-data-window-scope | Press Manage Site Data… in a pane sheet whose pane has a jar of its own | The table lists that jar's site data, not the global jar's; after Storage is changed to "Shared by all browser panes" in the same sheet, it lists the global jar's and the title and Remove All… confirmation say so |
| browser-settings-014 | history-group-contents | Open the History group in the Settings window, then in a pane sheet | Settings window: Record history, Keep visits for, Agent can see history; pane sheet: Record history, Agent can see history |
| browser-settings-015 | history-recording-gate | Recording on, pane private browsing on; navigate | No visit recorded |
| browser-settings-016 | history-recording-gate | Recording on, private browsing off; navigate | One visit recorded |
| browser-settings-017 | history-recording-gate | Recording off, private browsing off; navigate | No visit recorded |
| browser-settings-018 | agent-history-access-choices | Fresh settings store | `browser.agent.history_access` reads None; the popup lists All history, Current tab only, None |
| browser-settings-019 | agent-history-access-pane-override | Global All history; set the pane's row to None | The pane reads None, the global still All history; the row shows the override marker; Use Global Setting returns it to All history |
| browser-settings-020 | agent-history-access-gates-tool | Pane's effective value None; the agent asks for history | The request is refused with a reason |
| browser-settings-021 | keywords-follow-controls | Search the sidebar for "Autoplay", "Zoom", "Web Inspector", "Open sites in tabs", "Lockdown", "cookies" | Each finds the topic that now holds the control (Behavior, Appearance, General, Behavior, Privacy and Security, Privacy and Security) |
| browser-settings-022 | container-keywords-union | Read the container's search keywords before opening any topic | They contain every keyword of every listed topic |
| browser-settings-023 | every-browser-key-has-a-home | For every key in the browser key list, look for a row bound to it in the listed topics | Every key is found, the Chrome-only keys only when the Chrome topics are compiled in |
| browser-settings-024 | downloads-and-reset-unchanged | Open Downloads and Reset | Same rows and buttons as before the regroup |
| browser-settings-025 | buttons-have-tooltips | Inspect Manage Site Data… and the Site Data window's buttons | Each has a non-empty tooltip |
| browser-settings-026 | no-inline-help-labels | Inspect the Behavior, Appearance and added Privacy and Security groups | No explanation or empty-state text in the view; the topics' help content explains them |
| browser-settings-027 | toolbar-buttons-have-tooltips | Walk a browser pane's view tree, privacy toolbar off and on, with several tabs, and a Safari pane's extension toolbar | Every button found has a non-empty tooltip naming its action; an unlabeled extension falls back to its name, then "Run Extension" |
| browser-settings-028 | help-covers-regrouped-topics | Read Behavior's help in a pane's sheet, and Privacy and Security's help in either scope | Behavior has no "Open Sites in Tabs" topic in a pane; the Settings window's Appearance has a Tab Position topic naming where the control lives; History's help names Browser ▸ Show History; "Agent Can See History" is a topic |
| browser-settings-029 | help-covers-regrouped-topics | Open the Privacy and Security topic in an app with no history store; read the History group and the History help topic | No text under Record history; the History help says nothing is recorded whatever Record history says |

