
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `host` (`DetailTitleProvider`) | `DetailTitleHost` | required | The registration state and slot returned by `useDetailTitleHost` |
| `when` (`DetailTitleSuppressed`) | boolean | required | When true, withdraws every title registered below |
| `fallback` (`detailStripTitle`) | `ReactNode` | none | The host's own title; null or false opts out, and a published pane title overrides it |
| `title` (`useDetailTitle`) | `ReactNode` | none | The pane's title; null, undefined or false means no title |
| `levels` (`useSelectedTopicLabel`) | list of `{selectedId, items}` | required | The stack's levels, each with a selected id and its rows' ids and labels |

