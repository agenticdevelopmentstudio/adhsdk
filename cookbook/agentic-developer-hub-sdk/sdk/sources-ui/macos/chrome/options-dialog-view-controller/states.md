
| State | Appearance change |
|-------|------------------|
| Default | Dialog displays heading (if provided), rows, and Done button in vertical stack. |
| Heading hidden | Heading label is not visible; rows and Done button remain. |
| Row interaction | No change to dialog appearance; row changes propagate immediately. |
| Closed | Dialog is removed from view hierarchy; `onDidClose` fires (from `viewDidDisappear`) to allow cleanup. |

