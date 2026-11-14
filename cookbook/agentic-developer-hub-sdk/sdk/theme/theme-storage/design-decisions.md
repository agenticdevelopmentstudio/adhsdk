
**Decision**: Make persistence a protocol supplied by the host rather than a fixed settings location.
**Rationale**: The source comment says the theme model owns the model but not a settings system; a host with one supplies it instead of inheriting an opinion about where preferences live. The surface is exactly what `ThemeStore` touches because a seam wider than its one implementation would be guesswork.
**Approved**: pending

**Decision**: Never store built-in themes.
**Rationale**: `ThemeStore` concatenates custom themes with `BuiltInThemes.all` at read time, so an empty storage still yields a full catalog and a built-in change ships without a migration.
**Approved**: pending

**Decision**: Detect external changes by comparing stored values with last-seen values, not with a "writing" flag, and record the value before the write.
**Rationale**: The source documents that `UserDefaults.didChangeNotification` is delivered on a later run-loop turn, so a flag raised around a synchronous write is already down and every write would report itself; recording after the write arrives too late when the notification is synchronous. Value comparison also handles coalesced writes and a foreign write that stores the same value.
**Approved**: pending

**Decision**: Make `onExternalChange` a settable property that a conformer may never invoke.
**Rationale**: The source comment lets an in-memory test double leave it as a plain stored property. `ThemeManager` always installs it so that a theme chosen from a settings panel or a sync repaints without relaunch. It is a SHOULD rather than a MUST that a conformer stays silent on its own writes, because `ThemeManager.reload` already tolerates a duplicate call.
**Approved**: pending

**Decision**: Read an undecodable theme blob as an empty list and drop an unencodable write, with no error thrown or returned, logging each failure at error level.
**Rationale**: The source comment reasons there is nothing useful to do with an incompatible blob and that throwing would take the app down over a preference; an empty catalog still yields every built-in theme. The failure is surfaced only in the log, never to the caller, which this recipe records as a fact.
**Approved**: pending

**Decision**: Use the same two keys and JSON encoding as the host settings system.
**Rationale**: The source says a host that later grows a settings system can swap conformers and find the user's themes where it left them; the keys are load-bearing, and changing either orphans saved themes silently.
**Approved**: pending

