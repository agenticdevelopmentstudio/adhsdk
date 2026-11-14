
| State | Appearance change |
|-------|------------------|
| Default | Themed background, text in theme color, no border (unless theme declares one — see **optional-theme-border**) |
| Streaming (composing) | Caret appended to text (see **composing-caret**); on macOS, opacity does not change; streaming is a transient state |
| Failed | 1pt danger border; failure reason appended below text in caption font, danger color (see **failed-state-indicator**; announced on Web via **failure-announced-on-web**) |
| Flat theme | No background fill, no padding, no corner radius; text sits flush with message container edge (see **flat-theme-fill**) |
| Selected (web only) | `.pc-message-selected` class applied; appearance determined by theme CSS (see **selected-state**) |

