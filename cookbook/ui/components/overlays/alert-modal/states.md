
| State | Appearance change |
|-------|------------------|
| Alert mode (`cancelLabel` unset) | Single full-width confirm button in the footer |
| Confirm mode (`cancelLabel` set) | `DialogActions` renders cancel + confirm buttons |
| Busy, alert mode | Confirm button replaced by a `role="status"` `Loader2` spinner (`aria-label="Working…"`); dismissal blocked |
| Busy, confirm mode | `busy` forwarded to `DialogActions`, which replaces its own buttons with a status spinner; dismissal blocked |
| `destructive=true` | Tone icon/color forced to error; confirm button (alert mode) renders `"destructive"` variant; keyboard shortcuts forced off; in confirm mode, initial focus defaults to cancel |
| `dismissible=false` | `×` close affordance hidden; Escape/✕/programmatic close all blocked (backdrop/outside clicks are already unreachable regardless of `dismissible`) |
| `showIcon=false` | Leading tone icon omitted from the title |
| `keyboard="none"` | `Enter` ignored by the keydown listener; Escape-driven close blocked without invoking either callback |

