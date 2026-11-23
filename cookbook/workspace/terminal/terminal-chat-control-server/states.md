
| State | Appearance change |
|-------|------------------|
| Chat unconnected | Listed with `connected` false; every tool but `list` answers the not-connected error. |
| Chat connected | Listed with `connected` true; run, wait, interrupt and screen are served. |
| Chat released | Dropped from the next listing without a call to remove. |
| Pressed | Not applicable: the types have no interactive element. |
| Disabled | Not applicable: no enabled flag. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long run is reported by the session's own timeout. |
