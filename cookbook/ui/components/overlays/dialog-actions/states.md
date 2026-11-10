
| State | Appearance change |
|---|---|
| Idle, narrow container | even split, `[ Cancel ][ Confirm ]` filling the row |
| Idle, wide container | natural-width, right-justified (`justify-end`) |
| Forced `equal` | always equal-width regardless of container width |
| Forced `natural` | always natural-width right-justified |
| Confirm-only (no `cancelLabel`) | single confirm button, right-justified at its natural width; forced-equal does not stretch it |
| Destructive | confirm renders destructive variant; default initial focus is Cancel |
| Busy | buttons replaced by a `role="status"` spinner; no clicks fire |
| Confirm disabled | confirm button is disabled and does not respond to clicks |

