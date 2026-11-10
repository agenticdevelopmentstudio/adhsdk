
**Decision**: The search query is a controlled prop (`query` / `onQueryChange`), not internal state — the component never filters its own `groups`.
**Rationale**: This decoupling lets a host integrate server-side search (remote results already filtered by the server) without a local filter silently discarding matches whose label doesn't contain the query. For hosts that filter local groups themselves, the package exports `filterCommandItems(items, query)`: it trims and lowercases `query`, returns `items` unchanged when the trimmed query is empty, and otherwise keeps items whose `label`, `keywords`, `badge`, and `description` (joined, case-insensitively) contain the query substring.
**Approved**: pending

**Decision**: The first item in the flattened list is always preselected; the palette never opens with nothing highlighted.
**Rationale**: This shortens the interaction to two steps — type, then press Enter — the most common palette interaction, rather than requiring an extra arrow-down before Enter does anything.
**Approved**: pending

**Decision**: The highlight resets to the first item both when the displayed item set changes and separately when the dialog transitions from closed to open (see **reset-highlight-to-first-item**).
**Rationale**: The signature-based reset (keyed on item IDs) stops the highlight drifting to an unintended item when the list updates mid-interaction. The open-triggered reset stops a reopened palette from resuming the previous selection, avoiding an accidental re-run of the last selected command.
**Approved**: pending

**Decision**: A `loading: true` state does not replace the rendered list.
**Rationale**: Stale results are more useful than an empty pane. The loading indicator sits below the current results, signaling that more are coming without hiding what the user already has.
**Approved**: pending

**Decision**: Groups render in the order provided, and a group with zero items is dropped entirely — both its heading and its row (see **render-groups-in-order**).
**Rationale**: This lets a host declare groups unconditionally without cluttering the UI with empty sections.
**Approved**: pending

**Decision**: The component does not add its own Escape handler.
**Rationale**: The Dialog primitive already closes on Escape, so a second handler here would be a second definition of "how this closes" (see **open-change-on-dismiss**).
**Approved**: pending

**Decision**: `scrollIntoView()` is called with optional chaining (`?.`).
**Rationale**: jsdom, used in test suites, does not implement `scrollIntoView`. An unguarded call would throw in every host's test suite; optional-calling makes the scroll a cosmetic nicety that's simply absent in tests rather than a test blocker.
**Approved**: pending

**Decision**: ArrowDown at the end of the list wraps to the first item, and ArrowUp at the start wraps to the last (see **arrow-navigation**).
**Rationale**: Wrapping is more useful than "nothing happens," letting users cycle through short lists without reaching for the mouse.
**Approved**: pending

