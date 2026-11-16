
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

