
| State | Appearance change |
|-------|------------------|
| Open | Panel is visible with full opacity and visibility:visible |
| Closed (lightweight) | Panel has opacity:0 and visibility:hidden; content remains in DOM |
| Closed (full-featured) | Panel is unmounted (see **hide-on-close-unmount**) |
| Arrow enabled (full-featured, `arrow={true}`) | Diamond pointer (8px square) rendered at panel edge, rotated per `side` |
| Arrow disabled (full-featured, `arrow={false}`, default) | No pointer element rendered |
| Arrow (lightweight) | Always rendered; not conditional |

