
- **No panels** (MUST): The list is hidden, nothing is selected, and the detail is empty.
- **One panel** (MUST): No list; the panel fills the topic. It is selected once the view appears or a late-arrival selection runs.
- **Panel arrives after the section is on screen** (MUST): With nothing selected, the first panel is selected at once, because no appearance event will do it and an empty detail beside a list looks broken. If a panel was already selected, it stays selected.
- **Same panels, same order, handed over again** (MUST): The inherited split only redraws the rows and leaves the back and forward trail alone, as its comment says for a record window refreshing on a timer.
- **Selected panel removed** (MUST): The selection does not survive; with the view loaded and nothing selected, the first remaining panel is selected.
- **Different panel list** (MUST): The inherited split resets the back and forward trail, since its positions point at other panels.
- **View not yet loaded** (MUST): The list's visibility is recorded and applied when the view loads; selection waits for the view to appear.
- **Section name repeated by every panel** (MUST): Section headers are suppressed so the list does not show one repeating header.
- **Same section requested again by the coordinator** (MUST): The coordinator keeps one panel per section name and drops it when no panel claims the section, so the instance survives panels coming and going.
- **Concurrent access** (MUST): The type is confined to the main actor, so every call runs serialized on the main thread; there is no cross-thread access to define.
- **Network or offline state**: Not applicable: the panel does no network, disk or external work.
- **Boundary values**: One panel is the only boundary the source handles specially (list hidden at one or fewer); there is no upper limit.
- **Decoding from an archive** (MUST NOT): The coder initializer is unavailable and traps if called.

