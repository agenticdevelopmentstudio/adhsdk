
| State | Appearance change |
|---|---|
| Single page (`totalPages` ≤ 1) | Renders nothing |
| First page (`page` ≤ 1) | `Prev` disabled (dimmed, non-interactive); `Next` enabled |
| Middle page | Both `Prev` and `Next` enabled |
| Last page (`page` ≥ `totalPages`) | `Next` disabled; `Prev` enabled |
| Hover / focus / pressed | Inherited from `Button` outline (background lift, focus-visible ring, press dip) |

