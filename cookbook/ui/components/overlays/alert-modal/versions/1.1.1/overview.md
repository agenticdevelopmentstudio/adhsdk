
`AlertModal` (`packages/web/packages/ui/src/components/alert-modal.tsx`) is a
generalized, centered modal alert/confirm built on the shared `Dialog`
primitive. It renders one primary button (**alert mode**) when no
`cancelLabel` is supplied, or a primary + secondary pair via `DialogActions`
(**confirm mode**) when `cancelLabel` is supplied. Visibility is fully
controlled by the parent through the `open` prop. A leading tone icon
(`info`/`success`/`error`) can be shown in the title, the footer can be
replaced by a busy spinner, dismissal (Escape/✕ — backdrop/outside clicks never
dismiss the modal at all; see Edge Cases) can be disabled entirely, and the
keyboard shortcut policy (`Enter`/`Escape`) is configurable
per instance, including a `destructive` mode that forces the error tone and
disables keyboard shortcuts.

