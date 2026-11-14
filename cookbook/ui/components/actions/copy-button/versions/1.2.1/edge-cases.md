
- `getText()` returning `""` is the sanctioned "nothing to copy" signal — the host
  need not conditionally render the button; the click simply does nothing. A
  whitespace-only string is not treated as empty (see `skips-empty-text`).
- Clipboard write failure (insecure `http://` context, or a denied `clipboard-write`
  permission) is caught inside `useClipboard`, which resolves `false` and leaves
  `copied` false — the button stays idle with no error surfaced.
- Rapid re-clicks each reset the 1200 ms timer (`clearTimeout` then re-arm), so the
  check persists 1200 ms from the most recent successful copy, not the first (T9).
- Unmounting mid-flash is safe: `useClipboard` clears any pending timer on cleanup, so
  there is no state update after unmount (T10).
- The text is resolved lazily, so a stale render never copies stale data — the
  payload always reflects state at the instant of the click.

