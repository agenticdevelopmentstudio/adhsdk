
| State | Tab Appearance | Link Appearance |
|-------|----------------|-----------------|
| Active | `data-active=""`, `aria-selected="true"`, gold bottom border via `tabItemClass` | `data-active=""`, `aria-current="page"`, gold bottom border via `tabItemClass` |
| Inactive | No `data-active` attribute, `aria-selected="false"`, underline not visible | No `data-active` attribute, no `aria-current`, underline not visible |
| Focused | Inherits focus styling from `tabItemClass` definition | Inherits focus styling from `tabItemClass` definition |

