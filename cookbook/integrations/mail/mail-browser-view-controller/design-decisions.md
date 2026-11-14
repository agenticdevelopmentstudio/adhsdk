
**Decision**: The controller holds no mail logic; all state and actions live in `MailBrowserModel`, and the three panes only read and call it.
**Rationale**: The model's own header comment calls it "the tested unit"; the controller stays a thin composition root, so the model is tested without UI.
**Approved**: pending

**Decision**: The poll waits one interval before its first refresh instead of refreshing at once.
**Rationale**: The initial reload at view load already shows current data, so an immediate refresh would repeat it; the sleep comes first in the loop.
**Approved**: pending

**Decision**: Each tick calls the model's refresh-if-synced action, a read of the local store that never calls the remote mail provider.
**Rationale**: The class comment says it is "a read of the local store, never a Gmail call"; the poll costs no network or API quota. How the model decides a sync has landed belongs to the `MailBrowserModel` artifact.
**Approved**: pending

**Decision**: The poll runs only between appear and disappear.
**Rationale**: A window that is not on screen has no reason to reload; the task is cancelled on disappear and replaced on every appear.
**Approved**: pending

**Decision**: Errors are shown by the controller as an alert, not by the model or panes, and are cleared only after the user closes it.
**Rationale**: The model publishes `errorMessage` as state and cannot present UI; a sheet on the window keeps the user in context, and the modal fallback covers a view with no window.
**Approved**: pending

**Decision**: Pane widths are 180 to 320 for the sidebar, 280 minimum for the list and 360 minimum for the reader, with divider positions saved under "MailBrowserSplit".
**Rationale**: The values are fixed in source with no comment; their reasons are not recorded there, so this records what the code does.
**Approved**: pending

**Decision**: The controller's alert strings are literals, and `init(coder:)` traps.
**Rationale**: Technical debt that affects behavior: the strings cannot be localized without a change, and the controller cannot be loaded from a nib or storyboard. The debt is retired when the alert strings move to localization keys and the controller either supports archive construction or the trap is documented as permanent by a host-app decision.
**Approved**: pending

**Decision**: The refresh interval is accepted as given, with no check for zero or negative values.
**Rationale**: The source takes a `Duration` and passes it to the sleep; a very short interval only makes the local-store read run more often, and the only caller uses the default. Rejecting bad values at construction is left to a future change.
**Approved**: pending

**Decision**: Overlapping errors each present their own alert; the controller neither coalesces nor queues them.
**Rationale**: The source presents one alert per non-nil error value and leaves stacking to AppKit. A port to a platform that allows one dialog at a time (WinUI `ContentDialog`) needs a queue or coalescing step, which this spec does not define yet.
**Approved**: pending
