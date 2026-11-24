
The window manager is the top-level coordinator for the toolkit's window
infrastructure. It owns:

- a frame manager that persists window frames and visibility and reacts to
  screen changes (specified by the frame-manager and
  the screen manager ([adhsdk.ingredient.ui.windows.screen-manager](cookbook:1e58add7-d85d-4e62-b857-c5e3203795be))
  recipes);
- a window registry that looks up live instances of
  the single-instance window base ([adhsdk.ingredient.ui.windows.single-window-controller](cookbook:3f6268b8-410d-4d3c-979c-2a9f9f1534f3))
  by window id through weak references;
- the launch-restore pass (registering a restorable id and factory, running
  the launch-restore pass, reopening recents on launch);
- document recents recording (recording a show/close interaction) and the
  mirror of the recent-windows-count setting into the platform's
  recent-documents limit;
- an app-termination latch that lets the single-instance window base tell a
  user close from a quit close.

The recipe also covers the persistence layer it is built on: the
window-state storage protocol, its two implementations (the
settings-store-backed backend, the default, and the platform-preferences
backend), the window-state namespace key prefix that lets two copies of one
app keep separate layouts, and the window screenshot own-window capture
utility that lives alongside it.

Production code uses the shared window manager; tests construct an isolated
instance with a mock screen provider, in-memory storage, and an isolated
screen manager.

