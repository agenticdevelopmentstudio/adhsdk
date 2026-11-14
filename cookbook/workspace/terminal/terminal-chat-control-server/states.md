
| State | Appearance change |
|-------|------------------|
| Server stopped (default) | No socket exists; the object holds no listener. |
| Server listening | The socket file for this process's id exists, owner-only, and answers one request per connection. |
| Chat unconnected | Listed with `connected` false; a command action is refused with the not-connected error. |
| Chat connected | Listed with `connected` true; run, wait, interrupt and screen are served. |
| Chat released | Dropped from the next listing without a call to remove. |
| Pressed | Not applicable: the types have no interactive element. |
| Disabled | Not applicable: no enabled flag. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long run is reported by the session's own timeout. |

