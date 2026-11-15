
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mdv-001 | fetch-by-id | `id="abc123"` | Fetcher is called with id `"abc123"`. |
| mdv-002 | idle-state | `id=undefined` | Component enters idle state; no fetch occurs. |
| mdv-003 | fetch-timeout | `timeoutMs=5000`, fetch hangs >5s, using the default native-fetch fetcher | Fetch's `AbortSignal` is aborted; the fetcher rejects on abort, so the error state is shown. A fetcher that does not honor `AbortSignal` is not interrupted and can keep loading, or resolve, past the timeout instead. |
| mdv-004 | fetch-error-handling | Fetcher returns error with message | Error state displays error message in detail text. |
| mdv-005 | sanitized-rendering | Markdown with `<script>alert('xss')</script>` | Script tag is removed; no script executes. |
| mdv-006 | code-syntax-highlighting | Markdown with ` ```js\nvar x=1;\n``` ` (web) | Rendered `<code>` contains `<span>` elements carrying inline `--shiki-light`/`--shiki-dark` custom properties (JavaScript tokens are colorized); no bare color literal appears in the HTML. |
| mdv-007 | theme-persistence | (Web) User selects theme "dark"; app restarts | On restart, "dark" theme is still active. |
| mdv-008 | theme-palette-application | Active palette has `--mdv-text: #fff` | Content root carries inline style `--mdv-text: #fff`; rendered text resolves to `#fff` via `var(--mdv-text)`. |
| mdv-009 | toolbar-display | Component renders | Toolbar is visible with title and theme switcher. |
| mdv-010 | document-title-display | `title="My Doc"` in fetched document | Toolbar displays "My Doc". |
| mdv-011 | loading-state | Fetch is in progress | Spinner icon and "Loading…" text are visible. |
| mdv-012 | idle-state | Component renders before `id` is set | "No document selected" message is shown. |
| mdv-013 | empty-state | Content is `""` or whitespace-only | "Empty document" icon and message are shown. |
| mdv-014 | no-flash-theme | (Web SSR) User has persisted theme "dark" | Dark theme is applied before first paint (no visible theme flash). |
| mdv-015 | theme-switcher-touch-target | Component renders | Theme switcher control's hit area measures at least 44×44pt (iOS) / 48×48dp (Android). |
| mdv-016 | abort-on-id-change | `id` changes from `"abc"` to `"xyz"` while `"abc"`'s fetch is pending, using the default native-fetch fetcher | `"abc"`'s fetch's `AbortSignal` is aborted and the fetcher rejects; only `"xyz"`'s result (success or error) is reflected in state. If `"abc"` had already timed out before `id` changed, and the fetcher ignores `AbortSignal`, `"abc"`'s late result can instead overwrite `"xyz"`'s state — see Edge Cases. |
| mdv-017 | sanitized-rendering | Markdown link with text `link` and target `javascript:alert(1)` | Rendered `<a>` has no `href` attribute (disallowed protocol dropped by the sanitizer). |
| mdv-018 | sanitized-rendering | Raw HTML `<img src=x onerror=alert(1)>` | `onerror` attribute is stripped (not in the attribute allowlist); no script executes. |

