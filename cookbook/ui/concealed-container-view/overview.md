
A container view whose contents nothing outside the app may read: not the
accessibility API, not a screen reader, not a script that walks views, and not
a screen capture.

- **Accessibility.** The container is not an accessibility element and has no
  children, so the subtree under it does not exist to an accessibility client,
  whether a screen reader or a programmatic walk. A hit test that lands inside
  it resolves to the nearest element above it, so nothing below is ever named.
- **Scripting.** A script command that walks views stops at one of these. A
  static check says whether any view is inside one. A framework that cannot
  import this one asks the runtime for a marker protocol by its fixed
  Objective-C name instead.
- **Screen capture.** While the container is revealed and in a window, that
  window is blanked for screenshots, screen recording and screen sharing. The
  window goes back to read-only sharing when no concealed container in it is
  revealed any longer.

Use it around anything private, such as a terminal session or an editor of
private words, which the owner reveals when its privacy screen comes down and
conceals when it goes back up.

