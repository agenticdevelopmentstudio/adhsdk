
- **Role and structure**: Markdown is rendered with semantic HTML headings, lists, and emphasis. The viewer itself is a region containing document content.
- **Live regions**: Loading state uses `aria-live="polite"` and `aria-busy="true"` to announce fetch progress.
- **Error alerts**: Error state uses `role="alert"` so assistive technology announces failures immediately.
- **Color not sole differentiator**: Error state icon is distinct from idle/loading icons (different shapes, not color alone).
- **Keyboard navigation**: The theme switcher is a native `<select>` element (natively focusable and operable via keyboard; no extra ARIA needed). Links and interactive elements in rendered markdown are tab-navigable.
- **Minimum touch target**: See **theme-switcher-touch-target**.
- **Labels**: All interactive controls (theme switcher) have accessible labels via `aria-label` or visible text.

