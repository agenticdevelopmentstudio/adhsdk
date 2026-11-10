
- **Dirty and armed simultaneously** — `deleting` wins the label/grammar: the
  pair reads "Confirm delete", and ✓ commits the delete (the consumer decides
  what happens to the pending edits).
- **Modified clicks** (cmd/ctrl/shift/alt, middle-click) and `target="_blank"`
  links are not intercepted by the guard — they don't leave the page.
- **Cross-origin links** are left to the `beforeunload` prompt (the dialog
  cannot defer a cross-origin unload reliably).
- **Same-page hops** (identical pathname + search, hash-only, `href="#"`) are
  allowed through the guard — they destroy no state.
- **Self-navigating anchors** that consult `confirmNavigation()` in their own
  handler mark themselves `data-guarded-nav` so the guard's click interceptor
  skips them (no double prompt).
- **Commit failure** — the consumer keeps the dirty state, so the pair stays
  visible for retry; the control has no error rendering of its own.
  `useInlineDrafts` captures the failure into that row's error slot without
  disturbing other rows.
- **Keystrokes during a commit** — with `useInlineDrafts`, edits typed while a
  field commit is in flight survive as a still-dirty draft (`settle` drops only
  the committed values), so an in-flight save never discards later typing.
- **Busy cancel** — ✕ is soft-disabled (`aria-disabled`) during flight and
  ignores clicks, but keeps focus; a commit cannot be cancelled mid-request
  from the control.
- **Back-button sentinel cost** — after the page goes clean again, the
  consumed-or-not history sentinel may leave one extra same-URL entry (a
  second Back press); this is the only reliable way to interpose on `popstate`
  without desyncing the app router.

