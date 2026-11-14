
**Decision**: Use Shiki for syntax highlighting instead of Highlight.js or Prism; non-web implementations embed a WebView (or WebView2) hosting this same Shiki-based implementation rather than reimplementing highlighting with a native or alternate JS library.
**Rationale**: Shiki's TextMate-grammar-based highlighting is higher fidelity than DOM-tokenizer libraries like Highlight.js/Prism; hosting the same web implementation via WebView guarantees pixel-identical output across platforms instead of approximating it with a second highlighting engine.
**Approved**: pending

**Decision**: Resolve the Shiki theme from the `--scp-shiki-theme` CSS custom property on the panel root, with an explicit `theme` prop as an override.
**Rationale**: CSS custom properties let the toolkit theme system update every panel synchronously without React context plumbing; the `theme` prop remains available for callers that need explicit control.
**Approved**: pending

**Decision**: Catch and silently no-op clipboard write errors rather than surfacing them to the user.
**Rationale**: Copy-to-clipboard is a convenience feature; source treats a failed copy as non-critical. If clipboard becomes essential to a workflow, error handling should be revisited.
**Approved**: pending

**Decision**: Hold the "Copied" button label for a hard-coded 1200ms after a successful copy, with no prop to configure the duration.
**Rationale**: A fixed, short duration gives clear visual feedback without requiring configuration; other implementations should match this timing for consistency.
**Approved**: pending

**Decision**: When Shiki highlighting fails, degrade to plain text inside a semantic `<pre><code>` element with no error message shown.
**Rationale**: Preserves readability of the code even when highlighting is unavailable, while keeping the failure silent and non-disruptive to the surrounding UI.
**Approved**: pending

**Decision**: Use a `MutationObserver` on the `#adh-sdk-theme` `<style>` element to detect toolkit theme switches and re-read `--scp-shiki-theme`.
**Rationale**: The toolkit already changes themes by mutating this style element; observing it directly avoids adding a separate theme-change event system. Other platforms should use their own theme-change callback/observer equivalent (system theme callbacks, CSS-in-JS observer, etc.).
**Approved**: pending

