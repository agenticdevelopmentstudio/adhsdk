
None: no component in this family calls out to an analytics or telemetry API.
`DocNav` and `DocTableOfContents` only invoke the callbacks the host itself
supplies (`onToggleSection`, `onClose`), which the host may use to emit its own
events.

