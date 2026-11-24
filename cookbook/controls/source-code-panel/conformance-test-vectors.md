
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| scp-001 | render-code | code="const x = 1" | Code string appears in rendered output |
| scp-002 | accept-language | lang="python" | Shiki receives "python" as language identifier |
| scp-003 | theme-from-prop | theme="nord" | Component uses "nord" theme, ignoring CSS property |
| scp-004 | theme-from-css | theme not provided, --scp-shiki-theme set to 'github-light' | Component uses "github-light" theme (quotes stripped) |
| scp-005 | theme-fallback | theme not provided, --scp-shiki-theme not set | Component uses "github-dark" as fallback |
| scp-006 | watch-theme-changes | theme not provided, the `#adh-sdk-theme` `<style>` element's content mutates (e.g. toolkit switches theme), changing the computed `--scp-shiki-theme` value | Component re-reads `--scp-shiki-theme` and updates highlighted output |
| scp-007 | header-when-content | filename provided | Header renders with filename |
| scp-008 | header-when-content | filename not provided, showCopy=true | Header renders with copy button |
| scp-009 | display-filename | filename="App.tsx" | Header displays "App.tsx" |
| scp-010 | display-filename | filename not provided, lang="jsx" | Header displays "jsx" |
| scp-011 | show-copy-button | showCopy=true | "Copy" button is visible and clickable |
| scp-012 | copy-on-click | showCopy=true, code="test" | Clicking "Copy" button copies "test" to clipboard |
| scp-013 | show-copied-state | Copy succeeds | Button text changes to "Copied" |
| scp-014 | reset-copied-state | "Copied" state active for 1200ms | Button text returns to "Copy" after 1200ms |
| scp-015 | handle-copy-failure | clipboard access denied | No error state or message; component continues functioning |
| scp-016 | render-highlighted-html | Shiki highlight succeeds | Shiki HTML renders in `.scp-shiki` div; fallback `<pre>` is not rendered |
| scp-017 | fallback-to-preformatted | Shiki highlight fails | Code renders in `<pre><code>` with class `scp-fallback` |
| scp-018 | show-loading-state | Highlighting in progress | Fallback `<pre>` renders with `aria-busy="true"` |
| scp-019 | clear-busy-on-error | Shiki highlighting fails | Fallback `<pre>` renders with class `scp-fallback` and no `aria-busy` attribute; `.scp-shiki` is not rendered |
| scp-020 | support-maxheight | maxHeight="400px" | Body container has inline style `max-height: 400px` |
| scp-021 | support-classname | className="custom-theme" | Root div has class `scp-root custom-theme` |
| scp-022 | fallback-to-preformatted | lang=null (explicit null, not omitted) | Shiki rejects the invalid language identifier and throws; component falls back to `<pre><code>` with no `aria-busy` |
| scp-023 | fallback-to-preformatted | lang="not-a-real-language" | Shiki rejects the unknown identifier and throws; component falls back to `<pre><code>` with no `aria-busy`, same as any other highlight failure |
| scp-024 | render-highlighted-html | code contains `<script>alert(1)</script>` | Shiki escapes the code before generating HTML; the rendered `.scp-shiki` markup contains no executable `<script>` element |
| scp-025 | discard-stale-highlight-results | `lang` (or `code`/`theme`) changes while a previous highlight call for the old value is still pending | The stale result is discarded when it resolves; only the highlight for the latest `code`/`lang`/`theme` updates `html`/`error` |
| scp-026 | reset-copied-state | showCopy=true; Copy clicked successfully, then clicked again 800ms later | The label returns to "Copy" 1200ms after the second click (timer restarted); the first click's timer does not reset it early. Ports SHOULD restart the timer on each click |
| scp-027 | reset-copied-state | Copy clicked successfully, then the component unmounts before 1200ms elapse | The pending timer is cancelled; no state update occurs after unmount. Ports SHOULD cancel the timer on unmount |
| scp-028 | display-filename | filename="" (empty string), showCopy=true, lang="jsx" | Header renders; the filename label is empty because `filename ?? lang` does not fall back for an empty string (the reference does not substitute "jsx") |
| scp-029 | render-code | code="" (empty string) | Component renders without error; the output is empty or blank |
| scp-030 | handle-copy-failure | `navigator.clipboard` unavailable, Copy clicked | Click is a silent no-op; no error state, no console message, label stays "Copy" |
| scp-031 | watch-theme-changes | theme not provided, no `#adh-sdk-theme` element in the document | No observer is created; the theme is read once from `--scp-shiki-theme` (or falls back to "github-dark") and is not re-read |
| scp-032 | support-maxheight | maxHeight="200px", code longer than 200px when rendered | The full code string is rendered; the body container is limited to 200px and scrolls |
| scp-033 | discard-stale-highlight-results | theme not provided; `#adh-sdk-theme` content mutates several times in quick succession | Each mutation re-reads the theme and starts a new highlight; results from earlier pending calls are discarded and the output reflects the latest theme |
| scp-034 | header-when-content | showCopy=false, filename not provided | Header element does not render; only the code body is displayed |
