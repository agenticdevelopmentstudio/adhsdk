
- **Null and empty input**: A title of null, undefined or false MUST count as no title (`pane-has-title`); an empty string is not one of those values, so it counts as a title and registers. `fallback` null or false MUST opt out of a default title, while an empty string `fallback` makes the strip titled.
- **Boundary values**: With zero registered ids the active id MUST be undefined; with one it is that id. `useSelectedTopicLabel` MUST return undefined for an empty level list and the id itself when the id was never seen in the level's items.
- **Concurrent access**: Several panes MAY register at once; the last to register MUST win and the others MUST draw inline, so a second title is never lost. Registration uses functional state updates, so two registrations in one render batch both apply.
- **Slot not yet attached**: Until the slot element exists, `hoisted` MUST be false and the pane MUST draw inline; the layout effect moves the title once the slot is set.
- **Server rendering**: The slot is DOM, so on the server `hoisted` MUST be false and the inline title MUST stay in the HTML for crawlers and readers without JavaScript.
- **Hidden-but-mounted panes**: A pane the stack keeps mounted but hidden MUST be wrapped in `DetailTitleSuppressed`, so the strip does not name a pane that is not on screen.
- **Selected row filtered out**: When a search or filter drops the open row from its level, the strip title MUST hold the last label seen rather than blank, and the crumb falls back to the raw id.
- **Error states**: Not applicable: the module performs no network, file or other fallible I/O; its only failure path is a missing slot, covered above.
- **Offline or disconnected state**: Not applicable: the module is pure client rendering state with no network dependency.

