
**Decision**: details in a transient popover anchored to the gear, not in place
of the list.
**Rationale**: From the design. The user keeps the list in view and returns to
it by clicking away, with no Back step.
**Approved**: pending

**Decision**: the button bar's Options, Details… and removal move into the
details popover, which already offers them.
**Rationale**: Builder's reading of "the bottom button bar is removed": nothing
the bar did may be lost, and the details view already carries Options, the
store page and Remove Extension…, so no new control is needed (`dry`).
**Approved**: pending

**Decision**: Downloaded… accepts `.crx`, `.zip` and unpacked folders.
**Rationale**: A call recorded in the design for the owner to check; all three
reach the same staging path, so the extra forms cost one check each.
**Approved**: pending

**Decision**: the unsupported-download error is a new case on the host's
existing failure type.
**Rationale**: Builder's choice. The plan names it
`SafariExtensionHostError.unsupportedDownload`; the host already reports its
refusals through `SafariExtensionHost.Failure`, and one error type keeps
callers to one `catch`.
**Approved**: pending

