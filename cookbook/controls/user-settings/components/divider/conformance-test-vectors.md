
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| divider-001 | hr-element | No props | Rendered element is `<hr>` |
| divider-002 | base-class | No props | Element has class `{{app_prefix}}-divider` |
| divider-003 | extra-class-name | `className="custom-style"` | Element has classes `{{app_prefix}}-divider custom-style` |
| divider-004 | filter-empty-classes | `className={undefined}` or `className=""` | Element has only `{{app_prefix}}-divider`, no empty values in class list |
| divider-005 | filter-empty-classes | `className="   "` (whitespace only) | Raw class attribute is `"{{app_prefix}}-divider    "` (whitespace preserved, not trimmed); the parsed class list contains only `{{app_prefix}}-divider` — the whitespace-only string is truthy so it passes the filter but yields no additional class token |
| divider-006 | hr-element | No props | Rendered element exposes the implicit ARIA role `separator` |

