
The shared `CopyButton` in `@adh-sdk/ui` — the one "copy this" affordance across
every adh site. It is a small icon button that, on click, resolves a `getText()`
thunk and writes the result to the clipboard, then flashes a success check for a
short window. It composes two shared parts rather than re-implementing either: the
family `Button` (`variant="outline"`, `size="icon"`, shrunk to `size-6`) for the
chrome and press feel, and the `useClipboard` hook for the write + transient
`copied` flag. `useClipboard` is a small internal hook, not independently
catalogued in this cookbook, so it has no domain of its own to list under
`depends-on`.

The payload is a function, not a string: `getText()` runs at click time, so the
copied text reflects the current filter or selection even if the underlying rows
changed since render. If `getText()` returns an empty string, nothing is copied.
Clipboard failures — an insecure context, or a denied permission — are swallowed
inside `useClipboard`, so a copy that cannot happen is a silent no-op rather than an
error.

A single export ships from `@adh-sdk/ui/components/copy-button`: the `CopyButton`
component. It carries `"use client"` (clipboard access + the `copied` state) and is
fully self-driving — the only inputs are `getText`, the `label`, and an optional
`className`.

