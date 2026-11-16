
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
  nothing.
- **downloaded-refuses-links**: The extension host MUST refuse a downloaded
  item whose staged copy holds a symbolic link, with an error naming the item
  and the link, before the permission confirmation, and MUST leave nothing
  staged.
- **downloaded-off-main**: The extension host MUST read, copy and unpack a
  downloaded item off the main thread, so a large item never stalls the
  settings window.
- **url-prompt**: The URL… item MUST open a modal prompt with one text field and OK and
  Cancel buttons; Cancel MUST install nothing.
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

