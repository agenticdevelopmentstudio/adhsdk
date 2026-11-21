| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-row-per-event | three events | an `<ol>` with three items in the given order |
| T2 | tone-by-state, name-state | one event per state | rows carry "info", "running", "done", "warning", "failed"; dot classes follow the tone table |
| T3 | pulse-running | one running and one done event | only the running dot has `animate-pulse` |
| T4 | render-time | an ISO time | a `<time>` with that `dateTime`; with `formatTime` the formatted text shows |
| T5 | render-detail | an event with a detail, with and without `renderMarkdown` | the renderer's output, else a `<p>` with the text |
| T6 | connect-rows | three events | two connectors |
| T7 | show-empty | `events={[]}`, with and without `emptyLabel` | the label shown, no list |
| T8 | forward-class | `className="mt-2"` | the root carries it |
