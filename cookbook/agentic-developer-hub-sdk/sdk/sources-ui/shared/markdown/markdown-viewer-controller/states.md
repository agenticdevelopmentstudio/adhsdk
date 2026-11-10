
| State | Appearance change |
|-------|------------------|
| Idle | "No document selected" centered message. |
| Loading | Spinner icon, "Loading…" title, `aria-live="polite"` and `aria-busy="true"`. |
| Error | Alert icon (red/orange), "Failed to load document" title, error detail text below, `role="alert"`. No retry action; the caller re-triggers a fetch by changing `id` (or remounting). |
| Success | Rendered markdown content in active theme palette; toolbar displays document title. |
| Success–Empty | Document icon, "Empty document" title, "This document has no content yet" detail — distinct copy from Idle's "No document selected." |

