
- **Role**: Container with code content; use `<pre>` and `<code>` for fallback to provide semantic meaning
- **Copy button**: Semantic `<button type="button">` element with text content ("Copy" or "Copied")
- **Loading indicator**: When loading, fallback `<pre>` element has `aria-busy="true"` to announce in-progress state
- **Code representation**: Fallback uses plain `<pre><code>` structure; Shiki HTML is injected as-is without additional ARIA labels
- **Minimum touch target**: Copy button SHOULD be at least 44×44pt; source CSS (`.scp-copy { padding: 0.15rem 0.5rem; font-size: 0.7rem; }` in `source-code-panel.css`) renders it well under that size
- **Copy announcement**: The Copy to Copied label swap SHOULD be announced politely (see **announce-copy-result**). The source has no `aria-live` region, so the swap is not announced today.## Conformance Test Vectors

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
| scp-026 | show-copied-state | Copy succeeds twice, the second click 600ms after the first | In the reference implementation the label returns to "Copy" 1200ms after the first click (600ms after the second), because the first timer is not cleared; a port that restarts the timer shows "Copied" until 1800ms |
| scp-027 | display-filename | filename="", showCopy=true | Header renders with an empty filename label and the copy button; the language code is not shown |
| scp-028 | expose-use-source-code | `useSourceCode({ code, theme: 'github-dark' })` before highlighting resolves | Returns `{ html: null, loading: true, error: null }`, then `html` set and `loading: false` |
| scp-029 | default-languages-and-themes | lang="swift", theme="github-light" | Highlighting starts without loading an extra language or theme |
| scp-030 | load-on-demand | Two panels request the same non-default language at the same time | The language is loaded once and both panels highlight |
