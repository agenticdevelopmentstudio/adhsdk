
| Platform | Pattern | Behavior |
|----------|---------|----------|
| Web | `/#section-id` | Drawer closes; same-page fragment is targeted by id lookup, focus moves to target, scroll-behavior is smooth (set on host html element) |
| Web | `#encoded%20id` | Drawer closes; fragment is percent-decoded before id lookup |
| Web | `/other-page` | Drawer closes; browser navigates to URL (off-page link) |

