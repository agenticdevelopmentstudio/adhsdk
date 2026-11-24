
Window Matching is the logic layer that lets a window-context system recognise
"the same window" across app restarts and reboots, when the window's
system-assigned identifier has changed. It consists of:

- **title heuristics** — per-app title parsers that pull a stable identifying
  pattern (project name, page title, process) out of a window title, plus a
  shared separator splitter.
- **custom heuristic rules** — a user-defined rule (app name + substring or
  regex title pattern) — and an adapter that lets a rule act as a title
  heuristic.
- **a rule store** — persists rules to `heuristics.json` in a caller-supplied
  directory.
- **a heuristic registry** — a thread-safe, case-insensitive app-name →
  heuristic lookup pre-populated with five built-in heuristics, where custom
  rules override built-ins for the same app.
- **the window matcher** — creates a window fingerprint from a live window
  record, scores a live window against a fingerprint, and runs a greedy
  one-to-one assignment of dormant window snapshots (held in window contexts)
  to live windows.

Use it whenever a window must be persisted by identity rather than by a
volatile OS handle. The data types it consumes (a match strategy, a window
fingerprint, a live window record, a dormant window snapshot, a window
context) are specified in
Window Matching Core System Windows ([adhsdk.ingredient.system.system-windows.window-context-model](cookbook:d4b4359e-e9c8-439c-abcf-309fcc419348)).
The per-app built-in heuristics (Xcode, Warp, Brave, VS Code, Terminal) are
specified in
Window Matching Heuristics ([adhsdk.ingredient.system.system-windows.matching.title-heuristics](cookbook:77dbd38e-9acd-4053-ba54-738b45101f6b));
this recipe specifies only their registration, not their parsing rules.

