
None: no component in this family calls out to an analytics or telemetry API.
`DocNavTree` and `DocNav` only invoke the callbacks the host itself supplies
(`onToggleSection` on `DocNavTree`, `onClose` on `DocNav`), which the host may use
to emit its own events. `DocTableOfContents` takes no callbacks.

