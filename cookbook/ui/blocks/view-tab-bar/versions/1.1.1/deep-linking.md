
Route links in the component support standard `href` navigation:

| Platform | Behavior |
|----------|----------|
| Web | Links render as plain `<a href>` elements with no router integration point (no `renderLink`/`asChild` prop). Clicking triggers the browser's default navigation (a full page load) unless an ancestor of the component intercepts anchor clicks itself. The component does not handle routing; it passes through the `href` as provided. |

