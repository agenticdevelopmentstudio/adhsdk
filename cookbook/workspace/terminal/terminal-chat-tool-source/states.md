
| State | Appearance change |
|-------|------------------|
| No Terminal Chat connected | Every call returns the missing-chat error. |
| Terminal Chat connected | Run, wait and interrupt reach the session and return its text. |
| Chat connected or closed mid-conversation | The next call sees the change, because the lookup is per call. |
| Pressed | Not applicable: the source has no interactive element. |
| Disabled | Not applicable: no enabled flag; the missing-chat error stands in for it. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long command is reported by the session as still running. |

