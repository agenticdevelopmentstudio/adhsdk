
- **Long title**: The title is `shrink-0` with no `truncate`/ellipsis styling, so
  it never wraps or truncates on its own — it always renders at its full natural
  width. When title, filter, and actions together exceed the available row
  width, the filter field (`min-w-0 flex-1` within `max-w-xs`, or uncapped per
  **filter-width-cap**) shrinks first, then actions, before the title is
  affected. See T7.
- **No actions**: When no `actions` are supplied, only the title and filter render;
  the flex spacer has no visible effect.
- **No consumer state**: The header renders no filter state of its own (no "no results"
  message, no counts). Filtering, result display, and empty-state handling are
  entirely the consumer's responsibility.
- **Uncontrolled usage**: The consumer MUST feed the value passed to `onChange` back
  into `search.value`; a consumer that does not will see a frozen field (React's
  controlled-component pattern).

