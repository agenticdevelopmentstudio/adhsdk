
- **Empty code string**: Component accepts empty string and renders empty or blank output; Shiki may return empty HTML.
- **Null or undefined lang**: `lang` defaults to `'tsx'` only when the prop is `undefined` — JS default parameters do not apply to an explicit `null`. A `null` (or any other invalid identifier) reaches Shiki, which throws; the component catches it and falls back to `<pre><code>` (see **fallback-to-preformatted**, scp-022).
- **Invalid language identifier**: An identifier Shiki doesn't recognize causes `ensureLanguage`/`codeToHtml` to throw. The component catches it the same as any other highlight failure and falls back to `<pre><code>` (see **fallback-to-preformatted**, scp-023).
- **Clipboard API unavailable**: Copy button click is silently no-op; no error state, no console message.
- **Missing adh-sdk-theme element**: Theme observer skips setup; component uses fallback or prop theme without mutation watching.
- **Very long code string**: Component renders full string; maxHeight prop constrains visual container with overflow scroll if needed.
- **Rapid theme changes**: MutationObserver triggers on each mutation; rapid CSS updates result in rapid re-reads and re-renders. Each theme update starts a new highlight call, and any call still pending from a previous theme is discarded per **discard-stale-highlight-results**.
- **showCopy=false and no filename**: Header element does not render; code is displayed without header.
- **Unmount or rapid prop changes during highlighting**: `useSourceCode` tracks each highlight call with a local cancellation flag; a result that resolves after `code`/`lang`/`theme` changed, or after the component unmounted, is discarded and never updates state (see **discard-stale-highlight-results**, scp-025).

