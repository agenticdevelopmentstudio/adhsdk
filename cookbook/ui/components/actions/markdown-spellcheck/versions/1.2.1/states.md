
| State | Appearance change |
|---|---|
| Off (default) | Only the outline toggle is shown (`aria-pressed="false"`); no harper, no panel in the DOM |
| Loading (first enable) | Toggle pressed; panel shows a `Spinner` + "Checking…" |
| Ready — problems | Panel lists each flagged text + message + apply chips; toggle shows an error-tone count `Badge` |
| Ready — clean | Panel shows "No issues found." |
| Re-linting | Prior list stays visible (no "Checking…" flash) until fresh results replace it |
| Error | Panel shows a red `CircleAlert` + "Spell check is unavailable in this browser." |
| Dismissed / off | Popover unmounts, focus returns to the toggle, listed problems cleared |

