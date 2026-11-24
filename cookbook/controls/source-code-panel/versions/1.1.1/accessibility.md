
- **Role**: Container with code content; use `<pre>` and `<code>` for fallback to provide semantic meaning
- **Copy button**: Semantic `<button type="button">` element with text content ("Copy" or "Copied")
- **Loading indicator**: When loading, fallback `<pre>` element has `aria-busy="true"` to announce in-progress state
- **Code representation**: Fallback uses plain `<pre><code>` structure; Shiki HTML is injected as-is without additional ARIA labels
- **Minimum touch target**: Copy button SHOULD be at least 44×44pt; source CSS (`.scp-copy { padding: 0.15rem 0.5rem; font-size: 0.7rem; }` in `source-code-panel.css`) renders it well under that size

