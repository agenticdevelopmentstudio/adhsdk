---
id: 213f008f-6e11-4d6d-ba91-dbcd7e9330cc
title: "Extensions Settings Topic"
type: ingredient
version: 0.2.2
status: draft
language: en
created: 2026-11-15
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The web browser's Extensions settings topic: a table of installed extensions with an on checkbox, icon, name, version, description and gear, a header Add Extension menu and refresh button, and each extension's details in a popover from its gear."
platforms:
  - swift
  - macos
tags:
  - browser
  - settings
  - extensions
  - web-extensions
  - table
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SafariExtensionsTopicPanel.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SafariExtensionDetailsView.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/ExtensionURLPromptController.swift (adhsdk, planned)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/SafariExtensionHost.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/SafariExtensionLibrary.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/SafariAppExtension.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/WebStoreExtension.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserExtension.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserWindowController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/SafariExtensionsTopicTests.swift (adhsdk, planned)
approved-by: ""
approved-date: ""
---

# Extensions Settings Topic

## Overview

The Extensions topic of the web browser settings lists the web extensions
installed for one profile's browser panes — Chrome Web Store extensions and
the App Store's Safari extensions, both run by the platform's web extension
support — and is where they are added, turned on or off, updated and
inspected. It was titled "Safari Extensions".

The topic is one table filling the panel. Its columns are an unlabeled on
checkbox, the extension's icon, its name, its version, its description (the
one its manifest gives), and a gear. Name and Version fit their longest value
when the topic opens; Description takes whatever width is left. There is no
button bar under the table: the table's header row carries two right-aligned
icons, **+** for an "Add Extension" menu (Chrome Web Store…, Apple App
Store…, Downloaded…, URL…, then the App Store app extensions found on the
Mac) and **↻** to refresh the list and check for updates. The gear opens the
extension's details — site access, pinning, private browsing, file access,
options, store page and removal — in a popover pointing at that gear, rather
than replacing the list.

## Behavioral Requirements

- **topic-title**: The topic MUST be titled "Extensions".
- **column-order**: The table MUST have exactly these columns, in this order:
  on, icon, name, version, description, gear.
- **on-column-first-unlabeled**: The on column MUST be a checkbox column with
  an empty header title; checking or unchecking a row MUST turn that extension
  on or off.
- **no-source-column**: The table MUST NOT have a Source column; where an
  extension came from MUST remain shown in its details.
- **description-from-manifest**: The description column MUST show the
  description the extension's manifest declares.
- **name-version-autosize**: The topic MUST, each time it appears, size the Name
  and Version columns each to the width of their widest cell, header
  included, plus a small fixed margin.
- **description-only-flexible**: The table MUST, when resized, change the width
  of the description column only; on, icon, name, version
  and gear MUST keep their widths.
- **no-bottom-button-bar**: The topic MUST NOT show a row of buttons below the
  table (no Add…, Options, Details…, Get Extensions…, Check for Updates Now or
  Refresh button there).
- **header-buttons**: The table's header row MUST carry, right-aligned, an add
  (+) button and a refresh (circling arrows) button, in that order.
- **header-tooltips**: The add button's tooltip MUST be "Add Extension" and the
  refresh button's "Refresh and Check for Updates".
- **add-menu-items**: The add button MUST show a menu titled "Add Extension"
  whose first four items are, in order, "Chrome Web Store…", "Apple App
  Store…", "Downloaded…" and "URL…", followed by the App Store app extensions
  found on the Mac that are not yet installed.
- **chrome-web-store-item**: The Chrome Web Store… item MUST open the Chrome Web
  Store in one of the app's own browser windows (in a new tab of the
  destination pane when the topic is a pane's, else in a web browser window of
  its own, found again rather than opened anew).
- **app-store-item**: The Apple App Store… item MUST open the App Store's Safari
  extensions page.
- **app-extension-items**: The Add Extension menu MUST, when an app extension is
  chosen from it, copy that extension into the library through the normal install path, as today.
- **downloaded-accepts**: The Downloaded… item MUST present a file chooser that
  accepts a `.crx` file, a `.zip` file, or a folder containing `manifest.json`.
- **downloaded-rejects-unsupported**: The extension host MUST fail an install
  from a downloaded item that is none of those with an unsupported-download error naming the item,
  and MUST change nothing in the library.
- **downloaded-install-path**: The extension host MUST copy a chosen downloaded
  item into the library's staging area and then go through the normal stage, permission
  confirmation and commit path; declining the confirmation MUST install
  nothing. When the topic has no window to put the confirmation sheet on,
  the confirmation MUST be shown app-modally rather than declined, and an
  install error MUST be shown in an app-modal alert rather than dropped.
- **keyed-takeover-confirmed**: An install whose manifest `key` gives the id
  of an extension already installed, wherever the installed one came from,
  MUST be confirmed as a replacement naming the installed extension ("Replace
  “installed” with “new”?", button Replace), listing every permission and
  site the new files ask for, since a manifest key is public. Once accepted,
  the extension MUST become a local one (not from the Web Store, not from an
  app, its source not missing) granted only what was just agreed to, so the
  store's update check leaves it alone; private browsing and file access,
  which the confirmation does not ask about, MUST be off, and its sites MUST
  be the ones its kept site access setting grants (the listed sites under
  "On specific sites"), so it runs where its details page says.
- **downloaded-refuses-links**: The extension host MUST refuse an item
  whose staged copy holds a symbolic link, with an error naming the item and
  the link, before the permission confirmation, and MUST leave nothing
  staged; this holds for a downloaded item, a `.crx` address, a Web Store
  install and an app extension alike. The check MUST fail closed: a staged
  root that is not a directory or is itself a link, a tree that cannot be
  read, or an item whose type cannot be read MUST count as a link.
- **downloaded-off-main**: The extension host MUST read, copy and unpack a
  downloaded item, a `.crx` address's package, a Web Store package and an
  app extension's files off the main thread, so a large item never stalls
  the settings window.
- **download-size-capped**: A download of an extension package (a `.crx`
  address or the Web Store) MUST be refused, with a download error saying it
  is too large, once it is larger than 128 MB, whether or not the server
  announced its size, and MUST NOT be read further.
- **url-prompt**: The URL… item MUST open a modal prompt titled "Add an
  Extension from a URL" with one text field and OK and Cancel buttons, and
  no instruction line (what it accepts is in the topic's help); Cancel MUST
  install nothing.
- **url-prompt-validation**: The prompt's OK button MUST be enabled only while
  the field's text is a Chrome Web Store extension ID, a Chrome Web Store
  extension link, or an `http` or `https` address ending in `.crx`.
- **url-install**: The URL prompt's OK button MUST install the extension the text names through the
  normal download, permission confirmation and commit path.
- **refresh-checks-updates**: The refresh button MUST reload the list and check
  every extension for updates, reporting the outcome when the check finishes;
  it MUST be disabled while a change or check is in progress.
- **gear-opens-details-popover**: The topic MUST, when a row's gear is clicked,
  show that extension's details in a popover anchored to that gear, which closes when
  the user clicks outside it; the list MUST stay visible behind it.
- **details-actions-reachable**: The details popover MUST offer the
  extension's options page, its store page and its removal, so nothing the
  removed button bar did is lost.
- **list-follows-host**: The table and an open details popover MUST update when
  the extension host announces a change; a popover whose extension is no
  longer installed MUST close.
- **no-inline-help-labels**: The topic MUST NOT show explanatory or empty-state
  text in its view; an empty list MUST be an empty table, and explanation MUST
  go in the topic's help content. A library failure MAY show its error message
  where the rows would be.

## Appearance

- **Corner radius**: Not applicable — the settings framework's table card.
- **Padding**: The table fills the panel inside the settings framework's panel
  inset.
- **Font**: Not applicable — the table's standard row font; Version may use a
  monospaced-digit variant at the builder's choice.
- **Background**: Not applicable — settings framework table card.
- **Foreground/Text**: Column headers: empty (on), empty (icon), "Name",
  "Version", "Description", empty (gear). Description truncates at the column's
  trailing edge.
- **Border**: Not applicable — settings framework table card.
- **Shadow**: Not applicable — the popover takes the platform's own.
- **Min/Max size**: Name and Version are as wide as their widest cell plus the
  margin; the on, icon and gear columns are fixed and narrow; Description takes
  the rest. The popover's size and the exact symbols are the builder's choice.

## States

| State | Appearance change |
|-------|------------------|
| Default | The table lists installed extensions; header + and ↻ enabled. |
| Empty | An empty table; no text in it. |
| Library failure | The table shows no rows and the library's error message where they would be. |
| Change or check in progress | ↻ disabled; a second change is refused with a beep. |
| Details open | A popover points at the clicked gear; the list stays visible. |
| Extension off | Its on checkbox unchecked. |
| Pressed / Focused | Not applicable — platform controls' own states. |

## Accessibility

- **Role/trait**: Native table, checkbox, buttons and popover.
- **Label requirements**: The on checkbox's accessibility label is "On" for
  each row despite the empty header; the gear's is "Details"; the header
  buttons' labels match their tooltips. Identifiers keep the
  `settings.browser.safari.extensions` prefix (`.add`, `.refresh`,
  `.details`).
- **Announce state changes**: Not applicable beyond the platform's
  announcements for its own controls and popovers.
- **Keyboard / assistive-technology navigation**: The header buttons are in the
  key-view loop; the popover takes focus when it opens and closes on Escape.
- **Minimum tap target**: Not applicable — pointer-driven desktop controls of
  platform size.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| extensions-topic-001 | topic-title | Open the browser settings | A topic titled "Extensions"; none titled "Safari Extensions" |
| extensions-topic-002 | column-order, on-column-first-unlabeled | Load the topic | Column ids are on, icon, name, version, description, gear; the on column's title is empty |
| extensions-topic-003 | on-column-first-unlabeled | Uncheck an enabled extension's on checkbox | The host reports it off |
| extensions-topic-004 | no-source-column | Load the topic | No source column; the details popover still shows the source |
| extensions-topic-005 | description-from-manifest | An extension whose manifest description is "Blocks trackers" | Its description cell reads "Blocks trackers" |
| extensions-topic-006 | name-version-autosize | Extensions named "A" and "A Much Longer Extension Name"; the topic appears | The Name column is the longer name's width plus the margin; Version likewise for its widest value |
| extensions-topic-007 | description-only-flexible | Widen the settings window by 200 points | Only the description column grows |
| extensions-topic-008 | no-bottom-button-bar | Load the topic | No buttons below the table |
| extensions-topic-009 | header-buttons, header-tooltips | Inspect the header row | + then ↻, right-aligned; tooltips "Add Extension" and "Refresh and Check for Updates" |
| extensions-topic-010 | add-menu-items | Press + with one uninstalled App Store app extension on the Mac | Menu items: Chrome Web Store…, Apple App Store…, Downloaded…, URL…, then that app extension |
| extensions-topic-011 | chrome-web-store-item | Choose Chrome Web Store… in the Settings window | The store opens in one of the app's web browser windows; choosing it again reuses that window |
| extensions-topic-012 | app-store-item | Choose Apple App Store… | The App Store's Safari extensions page opens |
| extensions-topic-013 | app-extension-items | Choose the listed app extension and accept | It is copied into the library and listed |
| extensions-topic-014 | downloaded-accepts, downloaded-install-path | Install from a folder holding a valid `manifest.json` | The folder reaches the staging area and the permission confirmation is shown |
| extensions-topic-015 | downloaded-accepts | Install from a `.crx` file, then a `.zip` file | Each reaches staging and the confirmation |
| extensions-topic-016 | downloaded-rejects-unsupported | Install from `foo.txt` | Fails with an unsupported-download error naming `foo.txt`; library unchanged |
| extensions-topic-017 | downloaded-install-path | Install a downloaded item and decline the confirmation | Nothing is installed |
| extensions-topic-018 | url-prompt | Choose URL…, then Cancel | A modal with a field, OK and Cancel; Cancel installs nothing |
| extensions-topic-019 | url-prompt-validation | Type "abcdefghijklmnopabcdefghijklmnop" | OK enabled |
| extensions-topic-020 | url-prompt-validation | Type "https://x/y.crx" | OK enabled |
| extensions-topic-021 | url-prompt-validation | Type "hello", then "ftp://x/y.crx" | OK disabled for both |
| extensions-topic-022 | url-install | Enter a Web Store link and press OK, then accept | The extension is downloaded, confirmed and listed |
| extensions-topic-023 | refresh-checks-updates | Press ↻ | The list reloads and an update report is shown; ↻ is disabled until it finishes |
| extensions-topic-024 | gear-opens-details-popover | Click a row's gear, then click outside the popover | A popover anchored to that gear shows the extension's details over the visible list, then closes |
| extensions-topic-025 | details-actions-reachable | Open an extension's details | Options, store page and Remove Extension… are offered |
| extensions-topic-026 | list-follows-host | With details open, remove the extension from the popover and confirm | The row disappears and the popover closes |
| extensions-topic-027 | no-inline-help-labels | Load the topic with no extensions installed | An empty table with no text; the help content explains installing |
| extensions-topic-028 | downloaded-refuses-links | Install a folder with a manifest and a symbolic link to a file outside it | A symbolic-link error naming the link; no confirmation; nothing staged or installed |
| extensions-topic-029 | keyed-takeover-confirmed | Web Store extension "A" installed; install a downloaded folder whose manifest `key` gives A's id, named "B" | Confirmation "Replace “A” with “B”?" with a Replace button; once accepted the extension is local (not from the Web Store) with only the permissions just agreed to |
| extensions-topic-030 | download-size-capped | Install from a `.crx` address whose body is 129 MB, with and without a Content-Length header | A download error saying it is larger than 128 MB; nothing staged |
| extensions-topic-031 | downloaded-refuses-links | `symbolicLink(in:)` on a staged root that is itself a symbolic link, and on a plain file | Both answer "." |
| extensions-topic-032 | url-prompt | Choose URL… | The prompt's message is "Add an Extension from a URL" with no informative text |
## Edge Cases

- **Null and empty input**: No extensions: an empty table. An empty or
  whitespace-only URL field keeps OK disabled. An extension with no manifest
  description shows an empty description cell.
- **Boundary values**: A very long name widens the Name column to fit; the
  description column shrinks first and may truncate to nothing before the
  table scrolls horizontally.
- **Concurrent access**: One change at a time: an install, removal or update
  check started while another runs is refused with a beep, as today.
- **Error states**: A failed install, removal or update check is shown as an
  alert sheet on the settings window, or an app-modal alert when the topic
  has no window; the list reloads afterwards. An item holding a symbolic
  link, or one whose tree cannot be read, is refused before the
  confirmation (MUST, see `downloaded-refuses-links`).
- **Boundary sizes**: A package over 128 MB is refused as it downloads,
  announced or not (MUST, see `download-size-capped`).
- **Same key as an installed extension**: Files whose manifest `key` names an
  installed extension are confirmed as a replacement and, once accepted,
  become a local extension with fresh grants (MUST, see
  `keyed-takeover-confirmed`).
- **Offline or disconnected state**: An install from the Web Store, a `.crx`
  address or an update check fails with the network error, shown as above;
  Downloaded… still works offline.
- **Missing file or unreachable server**: A downloaded item removed between
  choosing and copying fails with the file error; nothing is staged.
- **Cancellation and timeouts**: Cancelling the file chooser, the URL prompt or
  the permission confirmation installs nothing.
- **Pane scope**: In a pane's settings the list is that pane's jar's
  extensions, and store and options pages open in a new tab of that pane.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| extension host | injected | the profile's host | Supplies the list, install, remove, enable and update operations. |
| destination | injected closure | none in the Settings window | The pane store and options pages open in; nil opens a web browser window. |
| name/version margin | points | 12 | Added to the widest cell when sizing Name and Version. |

The topic reads no settings key of its own.

## Deep Linking

Not applicable: the topic defines no URL scheme or route.

## Localization

The topic title, column headers, menu items, tooltips, the URL prompt's text
and buttons, and error messages are user-facing strings and localize with the
app's other settings strings. Extension names, versions and descriptions are
shown as the extension supplies them. Accessibility identifiers are never
localized.

## Accessibility Options

Not applicable: native controls honor the system's display options; the topic
reads none itself.

## Feature Flags

The topic is present only where the platform supports web extensions and the
profile has an extension host.

## Analytics

Not applicable: the topic emits no analytics event.

## Privacy

Before any extension is installed, by any of the four routes, the user is shown
what it asks to access and can decline. The topic itself sends nothing
anywhere; the store, an update check or a `.crx` address is contacted only when
the user chooses it.

## Logging

Not applicable: the design asks for no log line of the topic's own.

## Platform Notes

- **SwiftUI**: Not applicable as a home — the topic is AppKit; a SwiftUI host
  would use a `Table` with a toolbar-style header and `.popover` on the gear.
- **AppKit / UIKit**: `SafariExtensionsTopicPanel` (available macOS 15.4+) on a
  `ComposableSettings.EditableTableCard` with column ids `on`, `icon`, `name`,
  `version`, `description`, `gear`, `showsAddRemove = false` and
  `hidesHeaderWhenEmpty = false`; the description cell is
  `BrowserExtension.summary`. Name and Version widths are computed on every
  reload from `NSCell.cellSize` of every cell, header included, plus 12 pt;
  the table uses `uniformColumnAutoresizingStyle` and only the description
  column has `resizingMask = .autoresizingMask` (every other column `[]`, min =
  max = width), then `sizeToFit`. The header buttons are borderless
  `NSButton` subviews of the table's `NSTableHeaderView`, pinned trailing by
  Auto Layout, symbols `plus` and `arrow.triangle.2.circlepath`, with
  `toolTip`s that are also their accessibility labels. The gear shows an
  `NSPopover` (`behavior = .transient`, `preferredEdge: .maxY`) hosting
  `SafariExtensionDetailsView`, anchored to `frameOfCell(atColumn:row:)` of
  the gear; the details view has no Back control. Downloaded… uses an
  `NSOpenPanel` sheet and
  `SafariExtensionHost.installDownloaded(at:presentingOn:appModalWithoutWindow:)
  async throws -> Bool`, passing `appModalWithoutWindow` true when the topic
  has no window, so the confirmation `NSAlert` runs with `runModal()`
  instead of a sheet; the topic reports an error with
  `NSAlert(error:).runModal()` when it has no window. URL… uses
  `ExtensionURLPromptController` (message text only, no `informativeText`),
  validating with `WebStoreExtension.id(from:)`, and a `.crx` address goes to
  `SafariExtensionHost.install(fromAddress:presentingOn:)`, which reads it
  with `SafariExtensionLibrary.download(from:limit:session:)`: a
  `URLSession.bytes` stream refused past `maximumDownloadSize` (128 MB),
  checked against `expectedContentLength` first and every byte after; the
  store's `download(id:session:)` goes through it too. Every install path
  (downloaded, address, store `install(crx:)`, app extension) stages in
  `Task.detached(priority: .userInitiated)` and calls `refuseLinks`, which
  throws `Failure.symbolicLink` when `SafariExtensionLibrary.symbolicLink(in:)`
  finds one; that answers `"."` for a root that is not a directory (an
  lstat) or cannot be enumerated, the item itself when its
  `isSymbolicLinkKey` cannot be read, and the failing path when the
  enumerator's error handler fires. The confirmation is asked by
  `InstallKind` (`new`, `update`, `replacement(String)`); `installLocal`
  sets `replacement` with the installed one's display name when a keyed id
  is already installed, and `installStaged` then grants nothing from the
  old record and, after commit, sets `isFromWebStore` false, `appSource`
  nil, `sourceMissing` false and clears `grantedPermissions` and
  `grantedOrigins`. A downloaded
  item's record id is `WebStoreExtension.id(ofKey:)` of its manifest `key`
  when present, else `WebStoreExtension.localID(forPath:)` of its path or
  address, both Chrome's SHA-256 a–p mapping. Chrome Web Store… calls
  `WebBrowserWindowController.showExtensions(_:store:purpose:)`; Apple App
  Store… opens `SafariAppExtension.storeURL`.
- **Compose**: A desktop `LazyColumn` table with a header row of icon buttons
  and a `Popup` from the gear; a `FileDialog` for Downloaded….
- **React/Web**: A table with a header toolbar, a popover component anchored to
  the gear, and an `<input type="file">` accepting `.crx,.zip` plus a directory
  picker.
- **WinUI 3**: A `ListView` with a grid header, a `MenuFlyout` on +, a
  `Flyout` anchored to the gear, `FileOpenPicker`/`FolderPicker`, and
  `ToolTipService.ToolTip`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SafariExtensionsTopicPanel.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/SafariExtensionDetailsView.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Settings/ExtensionURLPromptController.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/SafariExtensionHost.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/WebStoreExtension.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/SafariExtensionsTopicTests.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/SafariExtensions/SafariExtensionLibrary.swift` | unverified |

## Design Decisions

**Decision**: details in a transient popover anchored to the gear, not in place
of the list.
**Rationale**: From the design. The user keeps the list in view and returns to
it by clicking away, with no Back step.
**Approved**: pending

**Decision**: the button bar's Options, Details… and removal move into the
details popover, which already offers them.
**Rationale**: Builder's reading of "the bottom button bar is removed": nothing
the bar did may be lost, and the details view already carries Options, the
store page and Remove Extension…, so no new control is needed (`dry`).
**Approved**: pending

**Decision**: Downloaded… accepts `.crx`, `.zip` and unpacked folders.
**Rationale**: A call recorded in the design for the owner to check; all three
reach the same staging path, so the extra forms cost one check each.
**Approved**: pending

**Decision**: the unsupported-download error is a new case on the host's
existing failure type.
**Rationale**: Builder's choice. The plan names it
`SafariExtensionHostError.unsupportedDownload`; the host already reports its
refusals through `SafariExtensionHost.Failure`, and one error type keeps
callers to one `catch`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|

Notes: no compliance checks have been run; the code does not exist yet.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.2.2 | 2026-11-16 | Mike Fullerton | Review fix: a keyed replacement resets private and file access and re-grants the sites it lists. |
| 0.2.1 | 2026-11-16 | Mike Fullerton | Every install stages off the main thread and refuses links (fail closed); 128 MB download cap; keyed takeover confirmed as a replacement; app-modal confirm and errors without a window; URL prompt has no instruction line. |
| 0.2.0 | 2026-11-15 | Mike Fullerton | downloaded-refuses-links and downloaded-off-main: a downloaded folder with a symbolic link is refused, and staging runs off the main thread |
| 0.1.1 | 2026-11-15 | Mike Fullerton | Platform notes follow the implementation: header buttons as header-view subviews, installDownloaded(at:presentingOn:), install(fromAddress:), key- or path-derived ids |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
