
- **Null and empty input**: No extensions: an empty table. An empty or
  whitespace-only URL field keeps OK disabled. An extension with no manifest
  description shows an empty description cell.
- **Boundary values**: A very long name widens the Name column to fit; the
  description column shrinks first and may truncate to nothing before the
  table scrolls horizontally.
- **Concurrent access**: One change at a time: an install, removal or update
  check started while another runs is refused with a beep, as today.
- **Error states**: A failed install, removal or update check is shown as an
  alert sheet on the settings window; the list reloads afterwards.
- **Offline or disconnected state**: An install from the Web Store, a `.crx`
  address or an update check fails with the network error, shown as above;
  Downloaded… still works offline.
- **Missing file or unreachable server**: A downloaded item removed between
  choosing and copying fails with the file error; nothing is staged.
- **Cancellation and timeouts**: Cancelling the file chooser, the URL prompt or
  the permission confirmation installs nothing.
- **Pane scope**: In a pane's settings the list is that pane's jar's
  extensions, and store and options pages open in a new tab of that pane.

