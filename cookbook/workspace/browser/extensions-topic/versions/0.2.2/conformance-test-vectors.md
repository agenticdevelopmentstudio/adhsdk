
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
