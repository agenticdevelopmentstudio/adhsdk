
Known gap, not "not applicable": the component hard-codes its user-facing
copy — the "Checking…" loading text, "No issues found." empty state, and the
"Spell check is unavailable…" error state, plus the per-suggestion
`Replace "<flagged>" with "<suggestion>"` accessible names (with "nothing" for
a removal), the "Remove" chip, the "No suggestion." fallback, the
`Spelling and grammar issues` list label, and the "Spelling & grammar" panel
caption (rendered uppercase) — with no
locale-sensitive formatting per source. Only the toggle's own text is
externalized, via the `label` prop (default `"Check spelling"`); a consumer
cannot localize the rest without editing this component. The linter is also
fixed to the American English dialect, so non-US English cannot be selected.

