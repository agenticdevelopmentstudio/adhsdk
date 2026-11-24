
**Decision**: Every command targets the browser pane in the key window, never
the last focused pane anywhere.
**Rationale**: The design's call for the owner to check: "Menu commands
target the key window's focused browser pane." A command must not reload a
page in a window the person is not looking at
(`principle-of-least-astonishment`).
**Approved**: pending

**Decision**: Show/Hide Privacy Toolbar writes a per-pane override, not the
global setting.
**Rationale**: The design's call: it matches the existing checkbox in the
pane's privacy popover, so the menu and the popover can never disagree.
**Approved**: pending

**Decision**: Only Back and Forward are rebindable; Reload and Stop keep
fixed keys outside the registry.
**Rationale**: The design names only Back and Forward as user-definable; the
plan keeps Reload and Stop fixed and asks that the registry not report them as
conflicts.
**Approved**: pending

**Decision**: How the bridge is wired is the builder's choice. The plan's
shape — an optional key command id on a menu contribution, and a bridge the
host calls for each item that carries one, observing the registry's
bindings-changed announcement — is the starting point.
**Rationale**: The design leaves "how the menu key-equivalent bridge is
wired" to the builder; today menu keys are fixed and the registry only
conflict-checks them.
**Approved**: pending

**Decision**: The privacy toolbar item's title with no target pane is the
builder's choice; the plan's test reads "Show Privacy Toolbar" in that case.
**Rationale**: The design defines the title only in terms of the target
pane's value.
**Approved**: pending

