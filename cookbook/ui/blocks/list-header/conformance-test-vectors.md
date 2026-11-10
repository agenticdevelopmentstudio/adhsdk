
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | one-row-layout, controlled-filter | `{ title: "Sites", search: { value: "", onChange }, actions: <Button> }` | All three parts render, in the order title → filter → spacer → actions; typing in the field fires `onChange` with the new text |
| T2 | optional-parts | `{ title: "Sites", actions: <Button> }` (no `search`) | Title and actions render; no search field appears; flex space still fills |
| T3 | optional-parts, filter-width-cap | `{ search: { value: "", onChange } }` (no `title`, no `actions`) | Only the search field renders; it remains capped at `max-w-xs` — the absence of `title`/`actions` does not make it grow |
| T4 | optional-parts, filter-width-cap | `{ title: "Sites", search: { value: "", onChange, grow: true }, actions: <Button> }` | Filter field grows beyond `max-w-xs`, but the trailing spacer (also `flex-1`) claims an equal share of the free space, so the filter stops short of `actions` with an equally wide empty gap between them |
| T5 | autofocus-remount | `{ search: { value: "", onChange, autoFocus: true } }` remounted | Input receives focus; re-renders (keystroke) do NOT steal focus again |
| T6 | accessible-names | Render with `ariaLabel="Filter list"` and `search.label="Search"` | Toolbar reports accessible name "Filter list"; input reports "Search" |
| T7 | Long title (edge case) | `{ title: "A title long enough to exceed the available row width", search: { value: "", onChange }, actions: <Button> }` | Title renders at full width, never wrapping or truncating (no `truncate`/ellipsis styling); the filter field (`min-w-0 flex-1`, see **filter-width-cap**) shrinks first to make room, then actions |
| T8 | touch-target-minimum | Render with default classes | Filter input's computed height is `h-9` (36px) and action buttons use the shared `Button` component's default sizing — both meet the 24×24 CSS px web minimum |

