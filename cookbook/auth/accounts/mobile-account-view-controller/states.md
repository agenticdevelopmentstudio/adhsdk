
| State | Appearance change |
|-------|------------------|
| Default | Signed out: Login row, plus Signup row when the account has a signup URL; the footer shows the account's summary when it is not empty. |
| Pressed | Login, Signup and Logout rows highlight with the default selection style while controls are enabled; the user and status rows never highlight. |
| Disabled | While the account is busy, Login, Signup and Logout stay visible in the tertiary label color, do not highlight, and ignore selection. |
| Focused | Not applicable: the source defines no focus state of its own; the rows have no focus styling beyond the table's defaults. |
| Loading | While the stored login is checked: one status row reading "Checking sign-in…" with a spinner, and no action rows. While busy: a status row reading "Working…" with a spinner; a signed-in user row and Logout stay visible when a user was shown before the busy state began; Login and Signup stay visible when none was. |

Signed in: user row and Logout row, with no summary footer. An account message replaces the footer in every state.

