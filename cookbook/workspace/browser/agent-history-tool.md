---
id: 4ef7f4f9-1fa0-4267-ad82-0f35ba92a7d1
title: "Agent History Tool"
type: ingredient
version: 0.1.4
status: draft
language: en
created: 2026-11-15
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The browser_history agent tool and the Agent can see history setting that gates it: All history, Current tab only, or None (the default), with every title and address concealed by the agent privacy gatekeeper."
platforms:
  - swift
  - macos
tags:
  - browser
  - agent
  - tools
  - history
  - privacy
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserHistoryTool.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserToolSet.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserPaneDirectory.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserAgentPrivacy.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserSettings.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SessionPrivacySettingsPanel.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHistoryToolTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserSettingsTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Agent History Tool

## Overview

This component lets an agent driving a browser pane read the visits the
person allows it to see, and nothing more. It has two parts: a setting,
**Agent can see history**, with three choices — All history, Current tab
only, None — and an agent tool, `browser_history`, that answers according to
the setting in effect for the pane it is called on.

The setting is global and can be overridden per pane, like every other pane
setting. It defaults to **None**: an agent working with privacy on has little
reason to see history, so the person opts in. With *All history* the tool
reads the browser's history store, as the History window shows it. With
*Current tab only* it reads the back/forward list of the tab the agent is
driving, with no store involved. With *None* it refuses and says where the
setting is.

Every title and address the tool returns passes through the agent privacy
gatekeeper's string path before the reply is assembled, so privacy words are
concealed whenever that feature is on — including in an address where the
word appears percent-escaped or with a space written as `+`.

The design is written before the code (design-first, from the more privacy
features design, section 1.4, and its phase 1 plan, Tasks 7 and 10).

## Behavioral Requirements

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

## Appearance

- **Corner radius**: Not applicable — the setting row is a standard
  settings row; the tool has no visual form.
- **Padding**: Not applicable — the settings panel's row layout.
- **Font**: Not applicable — the settings panel's row font.
- **Background**: Not applicable.
- **Foreground/Text**: Row title "Agent can see history"; pop-up items "All
  history", "Current tab only", "None", plus "Use Global Setting" on a pane's
  settings.
- **Border**: Not applicable.
- **Shadow**: Not applicable.
- **Min/Max size**: Not applicable.

## States

| State | Appearance change |
|-------|------------------|
| Access None (default) | The tool refuses with the settings sentence. |
| Access Current tab only | The tool lists the driven tab's back/forward entries. |
| Access All history | The tool lists the store's recent visits or search results. |
| Pane override set | The pane's row shows the override marker; the tool follows the pane's value. |
| Agent privacy on, words readable | Titles and addresses come back with privacy words concealed. |
| Agent privacy on, words unreadable or conflicting | The tool refuses with the pane's closed-privacy refusal. |
| Read-only pane | The tool is allowed. |
| Paused or hidden pane | The tool refuses as every browser tool does. |
| Loading | Not applicable — the tool answers once; nothing is shown while it runs. |

## Accessibility

- **Role/trait**: The setting is a standard pop-up button row.
- **Label requirements**: The pop-up's accessible label is "Agent can see
  history"; it carries a tooltip explaining what the agent sees under each
  choice.
- **Announce state changes**: Not applicable — the setting changes only by
  the person's own choice.
- **Keyboard navigation**: Standard settings panel navigation.
- **Minimum hit target**: Platform pop-up button size.
- **Contrast**: Not applicable — platform control rendering.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-history-tool-001 | access-three-choices, access-default-none, access-setting-key | Read the setting's cases and default with no stored value | Cases "All history", "Current tab only", "None" in that order; key `browser.agent.history_access`; default None |
| agent-history-tool-002 | access-pane-overridable | Write Current tab only into a pane's layered store | The key is not global-only; the pane store reports an override; the global value is still None |
| agent-history-tool-003 | access-row-placement | Build the Privacy and Security topic | Its History group holds a pop-up row titled "Agent can see history" with the three choices |
| agent-history-tool-004 | tool-listed, tool-arguments | List the browser tool set's tools | `browser_history` is listed with the required description and optional `pane_id`, `query`, `limit` |
| agent-history-tool-005 | none-refuses-with-reason | Access None; the store has 5 visits | The call fails with the exact settings sentence; the store and back/forward list are not read |
| agent-history-tool-006 | current-tab-back-forward-only | Access Current tab only; the store has 5 visits; the driven tab's back/forward list has 2 entries | The reply has exactly 2 visit lines, both from the back/forward list |
| agent-history-tool-007 | current-tab-newest-first | Access Current tab only; back/forward entries A (oldest), B, C; `query` "b" | The reply lists only B; with no query it lists C, B, A |
| agent-history-tool-008 | all-reads-store | Access All history; no query | The reply lists the store's recent visits, newest first |
| agent-history-tool-009 | all-reads-store | Access All history; `query` "docs" | The reply lists the store's search results for "docs" |
| agent-history-tool-010 | limit-default-and-cap | Access All history; 300 visits; `limit` absent, then 500 | 50 lines, then 200 |
| agent-history-tool-011 | effective-access-per-pane | Global All history; the pane overrides to None | The call fails with the settings sentence |
| agent-history-tool-012 | conceal-before-join | Privacy words {"Acme"}; a visit titled "Acme Inc" | The title appears with the stand-in, never "Acme" |
| agent-history-tool-013 | conceal-url-forms | Privacy words {"Acme Corp"}; addresses `https://x/?q=Acme%20Corp`, `https://x/?q=acme%20corp` and `https://x/?q=Acme+Corp` | No form of "Acme Corp" survives in any address |
| agent-history-tool-014 | privacy-off-unchanged, reply-lines | Agent privacy off; one visit with a title, address and time | One line holding the title, address and time exactly as stored |
| agent-history-tool-015 | closed-privacy-refuses | Agent privacy on with unreadable privacy words | The call fails with the pane's closed-privacy refusal; no visit returned |
| agent-history-tool-016 | same-access-checks | Call on a pane paused for the agent; then on a closed pane id | The paused refusal; then "pane … was closed; call browser_list" |
| agent-history-tool-017 | read-only-pane-allowed | Access All history on a read-only pane | The call succeeds; `browser_history` is in the read tool names; the store is unchanged |
| agent-history-tool-018 | reply-lines | Access All history; the store is empty | A reply saying no visits were found, not a failure |
| agent-history-tool-019 | conceal-with-every-word | Agent privacy on; the word "Acme" scoped to `acme.com`; the page in front on `example.com`; a visit to `https://acme.com/` titled "Acme" | The title and address come back with the stand-in, never "Acme" |
| agent-history-tool-020 | no-local-files | Access All history; the newest visit is `file:///Users/me/notes.html`, then two `https` visits; `limit` 2 | Two lines, both `https`; no `file:` address or its title appears |
| agent-history-tool-021 | no-local-files | Access Current tab only; the back/forward list holds a `file:` entry and an `https` entry | Only the `https` entry is listed |
| agent-history-tool-022 | closed-privacy-refuses, conceal-with-every-word | Agent privacy on; the page's words readable; the every-site words unreadable | The call fails with the closed-privacy refusal; no visit returned |
| agent-history-tool-023 | query-matches-concealed-text | Agent privacy on with "Acme" shown as "Globex"; a visit titled "Acme statement"; `query` "acme", then "globex" | "acme" replies that no visits were found; "globex" lists the visit as "Globex statement" |
## Edge Cases

- **Null and empty input**: No query lists recent visits (MUST, see
  `all-reads-store`); an empty history is a reply, not a failure (MUST, see
  `reply-lines`, agent-history-tool-018). An empty back/forward list
  likewise.
- **Boundary values**: `limit` absent or above 200 (MUST, see
  `limit-default-and-cap`, agent-history-tool-010); below 1 is the
  builder's choice (Design Decisions).
- **Concurrent access**: The setting is read at the time of the call (MUST,
  see `effective-access-per-pane`); a change while a call runs takes effect on
  the next call. The back/forward list is read on the main thread.
- **Error states**: None, closed privacy, paused, hidden or closed panes each
  refuse with their own sentence (MUST, see `none-refuses-with-reason`,
  `closed-privacy-refuses`, `same-access-checks`).
- **Offline or disconnected state**: Not applicable — history is local.
- **Missing file or unreachable server**: A history store that cannot be
  opened under All history fails with the tool set's usual error sentence,
  concealed like every other error reply.
- **Cancellation and timeouts**: Not applicable — one bounded read.
- **Escaped privacy words**: A privacy word hidden in an address's
  percent-escaped or `+`-escaped form is still concealed (MUST, see
  `conceal-url-forms`, agent-history-tool-013).
- **Local files**: A `file:` visit is never listed, in the back/forward
  list or the store (MUST, see `no-local-files`); the store leaves them out
  in its query so a limit of 50 still lists 50 visits the agent may see.
- **Words scoped to another site**: A privacy word scoped to one site is
  concealed on every line, including the lines of other sites and when the
  page in front is on a site the word does not apply to (MUST, see
  `conceal-with-every-word`).
- **Private browsing**: A pane browsing privately records no visits, so All
  history never contains its pages; Current tab only still reads the tab's
  own back/forward list, which the person can already see.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `browser.agent.history_access` | enum `all` / `currentTab` / `none`, per pane over global | `none` | What `browser_history` may return. |
| `limit` argument | int | 50 (max 200) | Most visits per reply. |
| `query` argument | string | none | Filters to visits whose title or address matches. |

## Deep Linking

Not applicable: the component defines no URL scheme or route.

## Localization

The display names ("All history", "Current tab only", "None"), the row
title, its tooltip and the refusal sentence are user-facing and localize with
the browser settings. The tool name, argument names and setting key are never
localized.

## Accessibility Options

Not applicable: the setting is a standard control and honours the system's
options already.

## Feature Flags

Not applicable: no flag gates the tool; the setting's default of None is the
gate.

## Analytics

Not applicable: the tool emits no analytics event.

## Privacy

This component exists to keep history from an agent unless the person
allows it. History is withheld by default; Current tab only exposes no more
than the tab already shows through its own Back and Forward; every title and
address passes through the gatekeeper's concealment before it leaves the
tool. The tool never writes, exports or retains history.

## Logging

Not applicable: the design asks for no log line of the tool's own; refusals
reach the agent as tool errors.

## Platform Notes

- **AppKit / UIKit**: `public enum BrowserAgentHistoryAccess: String,
  Codable, CaseIterable, Sendable { case all, currentTab, none }` with
  `displayName`; `UserSettings.browserAgentHistoryAccess` keyed
  `"browser.agent.history_access"`, default `.none`, listed in
  `BrowserSettings.allKeys` and not in `globalOnlyKeyNames`; the row lives in
  `SessionPrivacySettingsPanel`'s History group. `BrowserHistoryTool.run(access:query:limit:store:backForward:privacy:)`
  returns the reply string from a `BrowserHistoryStore?` and
  `[BrowserVisitLine]` (`title`, `url`, `when: Date?`), leaving out every
  visit `BrowserAutomation.isDrivable` refuses (a `file:` address; the store
  reads with `recent(limit:excludingLocalFiles: true)` and
  `search(_:limit:excludingLocalFiles: true)`, whose SQL adds
  `url NOT LIKE 'file:%'` before the limit; under Agent Privacy a query
  skips that SQL search and walks `recent(limit:before:excludingLocalFiles: true)`
  a `matchPageSize` page at a time, matching the concealed fields), concealing each field
  through the agent page's string path,
  `AgentPageBuilder(privacy:hideImages: false).conceal`, which applies
  `BrowserAgentPrivacy.concealing(_:)` (whose filter already adds the
  percent- and form-escaped forms, `includingURLForms`) and answers an empty
  string under a closed privacy. The privacy it is handed is
  `BrowserPaneHandle.historyPrivacy` `combined(with:)` the call's privacy:
  `historyPrivacy` is `WebBrowserPaneViewController.agentHistoryPrivacy()`,
  which is `.checking(PrivacyWordsVault.everySiteFilter)` (every enabled
  word, `[PrivacyWord].everySiteFilter`) while Agent Privacy is on, and a
  handle made without one while `agentPrivacy` is on gets `.unavailable`, so
  the call refuses rather than conceal with the page in front's words; the
  run refuses any closed privacy itself too (`closedRefusal()`).
  `BrowserPaneHandle` exposes the pane's
  effective access, its effective Hide Images (`hidesImages`, a required
  initializer argument with no default, which the page-reading tools build
  under and this tool does not read) and the driven tab's `WKBackForwardList`
  entries (current item first, then the back list newest first; forward
  entries are listed after them). `BrowserToolSet` adds the definition and
  dispatch, puts `browser_history` in `readToolNames`, and runs
  `requireAccess(for:on:)` first, which raises `closedRefusal()`. Refusals are
  `ToolError(sentence:)`.
- **SwiftUI**: The row is a `Picker` bound to the layered setting; the tool
  is shared non-UI code.
- **Compose**: A dropdown setting; the tool reads the WebView's
  `copyBackForwardList()` for Current tab only.
- **React/Web**: A select setting; Current tab only reads the driven tab's
  navigation history as the host browser exposes it.
- **WinUI 3**: A `ComboBox` setting; Current tab only reads WebView2's
  navigation history.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserHistoryTool.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserSettings.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserToolSet.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserPaneDirectory.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserEngine.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebKitBrowserEngine.swift` | unverified |

## Design Decisions

**Decision**: Three choices — All history, Current tab only, None — with
None the default.
**Rationale**: The owner's decision in the design: an agent with privacy on
has little reason to see history, so access is opt-in
(`secure-by-default`).
**Approved**: pending

**Decision**: Current tab only reads the tab's own back/forward list, never
the store.
**Rationale**: The design: it needs no store or schema change and exposes
nothing the tab does not already hold.
**Approved**: pending

**Decision**: Concealment happens per field, before the reply is joined, on
the gatekeeper's string path.
**Rationale**: The design routes every title and address through the same
string path as page titles elsewhere; concealing each field before joining
means a privacy word can never straddle a line break or separator and escape
the match. Phase 2 moves this onto `AgentPageBuilder.conceal` without changing
the behaviour.
**Approved**: pending

**Decision**: `browser_history` is a read tool, allowed on read-only panes.
**Rationale**: The plan: it only reads, so read-only access must not refuse
it.
**Approved**: pending

**Decision**: The reply's line format, the ordering of forward entries under
Current tab only, and `limit` below 1 being treated as 1 are the builder's
choices.
**Rationale**: The design and plan fix what is returned and the 50/200
limits, not the layout of a line or the handling of a non-positive limit.
**Approved**: pending

## Compliance

Not applicable — design-first draft; no code exists yet to check. The
checks are run when the code lands and the recipe is confirmed against it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.4 | 2026-11-16 | Mike Fullerton | Under Agent Privacy a browser_history query matches the concealed title and address, never the real text. |
| 0.1.3 | 2026-11-16 | Mike Fullerton | browser_history conceals with every enabled privacy word, never lists file: URLs, and is refused while the privacy side is closed. |
| 0.1.2 | 2026-11-16 | Mike Fullerton | Concealing through AgentPageBuilder(privacy:hideImages: false).conceal; BrowserPaneHandle.hidesImages is required and unused here. |
| 0.1.1 | 2026-11-15 | Mike Fullerton | The tool's pane argument is pane_id, as every other browser tool's is |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
