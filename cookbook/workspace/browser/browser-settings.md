---
id: 5a246e6c-2125-4427-a8ab-2f43f2fecba5
title: "Web Browser Settings Topics"
type: ingredient
version: 0.1.7
status: draft
language: en
created: 2026-11-15
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The web browser settings regrouped into General, Behavior, Appearance, Privacy and Security, Downloads, Extensions and Reset topics, each control keeping its setting key, with a Manage Site Data window and an agent history access choice."
platforms:
  - swift
  - macos
tags:
  - browser
  - settings
  - privacy
  - history
  - topics
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserSettings.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserSettingsPanelViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserBehaviorPanel.swift (adhsdk, planned)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserAppearancePanel.swift (adhsdk, planned)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SessionPrivacySettingsPanel.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/AgentPrivacySettingsPanel.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserSiteDataWindowController.swift (adhsdk, planned)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserEngineTopicPanels.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SafariExtensionsTopicPanel.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserSettingsTopicLayoutTests.swift (adhsdk, planned)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHistoryRecordingTests.swift (adhsdk, planned)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserSettingsTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserSettingsPanelScopeTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Web Browser Settings Topics

## Overview

The web browser's settings are one container of topics, shown in the app's
Settings window and, scoped to one pane, in that pane's settings sheet. This
ingredient fixes which topics exist, in what order, and which control lives in
each. The topics say what they hold: **General**, **Behavior**,
**Appearance**, **Privacy and Security**, **Downloads**, **Extensions** and
**Reset**, with the Chrome engine's topics between Extensions and Reset when
that engine is compiled in. The old History, Cookies, Media and Permissions
and Safari topics are gone; their controls moved into the topics above.

A setting key is a storage format: moving a control between topics changes
its group, never its key, so nobody's stored value is orphaned. Two things
are new rather than moved: a **Manage Site Data…** window that holds the site
data table the Safari topic used to show inline, and an **Agent can see
history** choice (All history, Current tab only, None; default None), global
and overridable per pane, which gates the agent's `browser_history` tool.
History recording also gains a rule: nothing is recorded while private
browsing is on for the pane. Sidebar search keeps finding every control
because each topic's search keywords move with its controls.

## Behavioral Requirements

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

## Appearance

- **Corner radius**: Not applicable — the topics use the settings framework's
  groups and rows; this ingredient sets no geometry of its own.
- **Padding**: Not applicable — the settings framework's panel inset and group
  spacing.
- **Font**: Not applicable — the settings framework's row and group title
  fonts.
- **Background**: Not applicable — the settings window's background.
- **Foreground/Text**: Topic titles exactly "General", "Behavior",
  "Appearance", "Privacy and Security", "Downloads", "Extensions", "Reset".
  Group titles as listed in the control table under Configuration. The
  Behavior topic's sidebar symbol is a tapping hand; Appearance's is a text
  size symbol.
- **Border**: Not applicable — settings framework cards.
- **Shadow**: Not applicable — the Site Data window takes the platform's
  standard window shadow.
- **Min/Max size**: The Site Data window has a minimum size that shows both
  columns and its buttons; its exact sizes are the builder's choice.

## States

| State | Appearance change |
|-------|------------------|
| Settings window scope | Every topic shows every row it holds, including "Open sites in tabs" and "Keep visits for". |
| Pane scope | "Open sites in tabs" and "Keep visits for" are absent; pane-overridable rows show the override marker when the pane overrides them. |
| Chrome pane scope | General leaves out its Media and Web Inspector groups, which only WebKit honours, as the Safari topic they came from was left out of a Chrome pane's sheet. |
| Overridden (pane scope) | The row shows the override marker and "Use Global Setting", which removes the pane's value. |
| Site Data window open | The window is modal to the app; the settings window behind it does not take input until Done closes it. |
| Site Data loading | Refresh re-reads the store; the table keeps its rows until the new answer arrives. |
| Disabled | A row whose setting cannot change in the current scope (for example "Private browsing", global-only, in a pane sheet) is disabled, as today. |
| Pressed / Focused | Not applicable — platform controls' own states. |

## Accessibility

- **Role/trait**: Every control is a native checkbox, popup, slider, text
  field or button with its own platform role.
- **Label requirements**: Each control's title is its accessibility label.
  Moved controls keep their accessibility identifiers; new ones are
  `settings.browser.site-data.manage` for the button and a
  `settings.browser.session-privacy.agent-history-access` identifier for the
  agent history popup.
- **Announce state changes**: Not applicable beyond the platform's own
  announcements for native controls.
- **Keyboard / assistive-technology navigation**: Native controls in the
  settings framework's key-view order; the Site Data window takes keyboard
  focus when it opens and closes on Escape as well as Done.
- **Minimum tap target**: Not applicable — pointer-driven desktop controls of
  platform size.

## Conformance Test Vectors

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

## Edge Cases

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

## Configuration

The control table. Keys never change when a control moves
(`keys-never-change`); "new" marks a key this work adds.

| Topic | Group | Control | Key |
|-------|-------|---------|-----|
| General | User Agent | Custom user agent | `browser.custom_user_agent` |
| General | Media | Allow AirPlay | `browser.allows_airplay` |
| General | Web Inspector | Allow Web Inspector | `browser.web_inspector_enabled` |
| Behavior | Windows | Open sites in tabs (Settings window only) | `browser.new_opens_tabs` |
| Behavior | Page | Enable JavaScript | `browser.javascript_enabled` |
| Behavior | Page | Block pop-up windows | `browser.blocks_popups` |
| Behavior | Home Page | Address | `browser.home_page` |
| Behavior | Playback | Autoplay | `browser.autoplay` |
| Appearance | Page | Zoom | `browser.page_zoom` |
| Appearance | Page | Minimum font size | `browser.minimum_font_size` |
| Appearance | Tabs | Tab position (pane override) | `browser.tabs.positions` (new) |
| Privacy and Security | General | Pause all events (pane sheet only) | none — the pane's own state |
| Privacy and Security | General | Show privacy toolbar | `browser.privacy.show_toolbar` |
| Privacy and Security | Input | Disable keyboard events | `browser.privacy.keyboard` |
| Privacy and Security | Input | Disable mouse and scrolling events | `browser.privacy.mouse` |
| Privacy and Security | Input | Disable pointer tracking | `browser.privacy.pointer_tracking` |
| Privacy and Security | Input | Disable drag and drop | `browser.privacy.drag_and_drop` |
| Privacy and Security | Focus and visibility | Disable activation events | `browser.privacy.hide_activation` |
| Privacy and Security | Coding Partner | Agent access | `browser.privacy.agent_access` |
| Privacy and Security | Coding Partner | Agent while paused | `browser.privacy.agent_while_paused` |
| Privacy and Security | Agent Privacy | Conceal privacy words from agents | `browser.agent_privacy.enabled` |
| Privacy and Security | Agent Privacy | Hide Images | `browser.privacy.hide_images` |
| Privacy and Security | Storage | Cookie and storage jar | `browser.privacy.storage_jar` |
| Privacy and Security | Scripts | Third-party content | `browser.privacy.third_party_content` |
| Privacy and Security | Scripts | Capture page console | `browser.privacy.console_capture` |
| Privacy and Security | Cookies | Accept cookies | `browser.accepts_cookies` |
| Privacy and Security | Cookies | Private browsing (global only) | `browser.private_browsing` |
| Privacy and Security | Camera and Microphone | When a page asks | `browser.media_capture` |
| Privacy and Security | Protection | Warn about fraudulent websites | `browser.fraud_warning` |
| Privacy and Security | Protection | Upgrade known sites to HTTPS | `browser.upgrades_to_https` |
| Privacy and Security | Protection | Lockdown Mode | `browser.lockdown_mode` |
| Privacy and Security | Site Data | Manage Site Data… | none — opens the Site Data window |
| Privacy and Security | History | Record history | `browser.records_history` |
| Privacy and Security | History | Keep visits for (Settings window only) | `browser.history_retention` |
| Privacy and Security | History | Agent can see history | `browser.agent.history_access` (new, default None) |
| Downloads | Location | Folder, Choose Folder…, Use Downloads Folder | `browser.download_directory` |
| Downloads | Location | Ask where to save each file | `browser.asks_download_location` |
| Extensions | — | see the Extensions Settings Topic recipe | none |
| Chrome (compiled out) | Developer Tools, Performance | Allow developer tools; Remote debugging port; Use hardware acceleration | `browser.chrome.devtools_enabled`, `browser.chrome.remote_debugging_port`, `browser.chrome.hardware_acceleration` |
| Chrome Extensions (compiled out) | Updates | Check for updates | `browser.chrome.extension_update_interval` |
| Reset | — | Use Global Settings for This Pane; Reset Browser Settings… | none |

Topics no longer listed: History (its Recording group moved to Privacy and
Security › History; its visit list and Clear History… are the History
window's), Cookies (→ Privacy and Security › Cookies), Media and Permissions
(Playback → Behavior, Camera and Microphone → Privacy and Security), Safari
(Protection → Privacy and Security, Media › AirPlay and Web Inspector →
General, Site Data → the Site Data window).

## Deep Linking

Not applicable: the topics define no URL scheme or route of their own.

## Localization

Topic titles, group titles, control titles, the three agent history choices
("All history", "Current tab only", "None"), the Site Data window's title and
buttons, and every tooltip are user-facing strings and localize with the
app's other settings strings. Setting keys and accessibility identifiers are
never localized.

## Accessibility Options

Not applicable: native settings controls honor the system's display options;
the topics read none themselves.

## Feature Flags

The Chrome and Chrome Extensions topics are present only when the Chrome
engine is compiled in (`CHROME_BROWSER_PANE`); it is unset today. The
Extensions topic is present only where the platform supports web extensions.

## Analytics

Not applicable: the topics emit no analytics event.

## Privacy

"Agent can see history" defaults to None, so an agent sees no browsing
history until the user chooses otherwise, globally or for one pane. A pane in
private browsing records no visit. The Site Data window removes site data only
after the user confirms. Nothing here sends data anywhere.

## Logging

Not applicable: the design asks for no log line of the topics' own.

## Platform Notes

- **SwiftUI**: Not applicable as a home — the settings are AppKit
  `ComposableSettings`; a SwiftUI host would show the same topics as `Form`
  sections in a `NavigationSplitView`, keys unchanged.
- **AppKit / UIKit**: The container is `BrowserSettingsPanelViewController`
  (`ComposableSettings.SettingsPanelSplitViewController`); each topic is a
  `BrowserTopicPanel(title:symbol:binding:)` subclass. New:
  `BrowserBehaviorPanel` (symbol `hand.tap`) and `BrowserAppearancePanel`
  (symbol `textformat.size`); `BrowserGeneralPanel` keeps only User Agent and
  gains the Media and Web Inspector groups; `BrowserPrivacySettingsPanel`
  (`SessionPrivacySettingsPanel.swift`) is retitled "Privacy and Security" and
  gains the five groups. Removed: `BrowserHistoryPanel`,
  `BrowserCookiesPanel`, `BrowserMediaPanel` and `SafariBrowserTopicPanel`.
  `BrowserSiteDataWindowController: NSWindowController` with
  `init(siteData: BrowserSiteData, removeAllDetail: String? = nil)` (the
  confirmation's detail, worded for the jar) and `runModal(for: NSWindow)`
  holds the
  `ComposableSettings.EditableTableCard` the Safari topic built; its window
  has `.titled`, `.closable`, `.resizable` style and is run with
  `NSApp.runModal(for:)`, not as a sheet. The recording gate is a static
  `recordsHistory(globalRecords:paneIsPrivate:) -> Bool` (or a small
  `BrowserHistoryRecordingPolicy`). The agent history setting is
  `public enum BrowserAgentHistoryAccess: String, Codable, CaseIterable,
  Sendable { case all, currentTab, none }` with `displayName`, and
  `UserSettings.browserAgentHistoryAccess` keyed
  `"browser.agent.history_access"`, listed in `BrowserSettings.allKeys` and not
  in `globalOnlyKeyNames`. Per-pane overrides go through
  `LayeredSettingsStore` and `BrowserSettingsBinding.add(...)`, which draws the
  override marker. Tooltips are `NSButton.toolTip` (a segmented control's
  per segment, `setToolTip(_:forSegment:)`). The privacy toolbar's row in
  `WebBrowserPaneViewController` also holds the Hide elements from agent
  button and the Agent view control (recipes
  `workspace/browser/hide-from-agent` and `workspace/browser/agent-views`),
  which `toolbar-buttons-have-tooltips` covers too. The pane's effective
  Hide Images is `agentHidesImages`, read from its own layered settings,
  the one value the browser tools (`BrowserPaneHandle.hidesImages`) and
  the agent views build under. `browser.hidden_items.notice_shown` (the
  element picker's one-time notice) is in `globalOnlyKeyNames` and not in
  `BrowserSettings.allKeys`, so it has no row.
- **Compose**: Desktop settings as a list-detail layout; each topic a
  composable over a shared settings repository, keys unchanged; the Site Data
  window a `DialogWindow` with `resizable = true`.
- **React/Web**: A settings route per topic; the Site Data window a
  modal dialog that can be dragged and resized; tooltips via `title`.
- **WinUI 3**: A `NavigationView` with one page per topic; the Site Data window
  a separate modal `AppWindow` with an `OverlappedPresenter` that is
  resizable; tooltips via `ToolTipService.ToolTip`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserBehaviorPanel.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserAppearancePanel.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserSiteDataWindowController.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/BrowserSettingsPanelViewController.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SessionPrivacySettingsPanel.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/SafariExtensionToolbar.swift` | unverified |

## Design Decisions

**Decision**: a moved control keeps its key; only its group changes.
**Rationale**: A key is a storage format once shipped; renaming one orphans
every user's stored value. Moving controls is a presentation change and must
stay one (`optimize-for-change`).
**Approved**: pending

**Decision**: site data moves out of the topic into a modal Site Data window.
**Rationale**: From the design. A table of every site's data crowds a topic
that is otherwise rows of switches; a resizable window gives the table the
room it needs.
**Approved**: pending

**Decision**: "Agent can see history" defaults to None and is per pane.
**Rationale**: The owner's decision: an agent with privacy on has little
reason to see history. Per pane follows the layered settings unit, so the
override covers all of a pane's tabs.
**Approved**: pending

**Decision**: the recording gate is one function every record call goes
through.
**Rationale**: A private pane must never record, and a second call site that
forgot the private check would leak a visit; one gate keeps the rule in one
place (`dry`).
**Approved**: pending

**Decision**: "Open sites in tabs" and "Keep visits for" stay Settings-window
only, as today.
**Rationale**: Builder's reading of existing behavior: the first governs a
window's New command, the second a store shared by the whole app; neither is
a pane's to override.
**Approved**: pending

**Decision**: the "every key has a home" check counts the Chrome topics only
when they are compiled in.
**Rationale**: Builder's choice. With the Chrome engine compiled out its four
keys have no topic to live in, and a check that failed on them would only be
silenced.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|

Notes: no compliance checks have been run against the code yet.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.7 | 2026-11-16 | Mike Fullerton | Review fix: Manage Site Data resolves its jar on click and names it in the title and confirmation. |
| 0.1.6 | 2026-11-16 | Mike Fullerton | The no-history-store note moves from under Record history to the History help topic. |
| 0.1.5 | 2026-11-16 | Mike Fullerton | Privacy toolbar row with the hide-from-agent button and agent view control; agentHidesImages; notice-shown key is global only. |
| 0.1.4 | 2026-11-15 | Mike Fullerton | help-covers-regrouped-topics allows a where-to-find-it topic that names where the control lives |
| 0.1.3 | 2026-11-15 | Mike Fullerton | Toolbar buttons have action tooltips; help follows the regrouped topics' groups and points history to Browser > Show History |
| 0.1.2 | 2026-11-15 | Mike Fullerton | Site data removal reports no failure; a Chrome pane's sheet leaves out Protection and Site Data; the Site Data window takes the Remove All detail |
| 0.1.1 | 2026-11-15 | Mike Fullerton | A Chrome pane's sheet leaves General's Media and Web Inspector groups out. |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
