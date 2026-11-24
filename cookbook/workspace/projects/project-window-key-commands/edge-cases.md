
- **Null and empty input**: No command window (`nil`) is declined and logged as
  `none` (MUST). A window with an empty title is logged with the empty title.
- **Boundary values**: The two chords are Command-0 and Command-1; another
  window's command may use the same chord, which is why a decline returns
  `false` rather than consuming the key (MUST).
- **Concurrent access**: Everything is main-actor isolated, so the window is read
  and toggled on one actor with no interleaving (MUST).
- **Error states**: Nothing throws. A wrong window is a decline, not an error;
  the only signal is the debug log, and the user sees nothing (a fact of the
  source, whose comment calls a silent chord the hardest thing to debug).
- **Window closed between resolve and toggle**: Not applicable: resolution and the
  toggle call happen in one synchronous main-actor call.
- **Offline or disconnected state**: Not applicable: no network or file access.

