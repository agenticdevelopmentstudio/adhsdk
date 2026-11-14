
- **Role**: `.lp-shot` is a plain `<div>` with no ARIA role; no interactive role is required since Shot has no interactive elements.
- **Label**: The `title` prop is rendered as ordinary visible text content in `.lp-shot__name`, so screen readers announce it as text when they reach it; no explicit `aria-label` is applied, and none is needed since the title is real text rather than an icon or image standing in for one.
- **Alt text**: Host is responsible for adding alt text to any `<img>` or `<video>` elements passed via the `media` prop; Shot renders media without modification.
- **Placeholder accessibility**: The three dots (`.lp-shot__dot`) are empty `<span>` elements with no text content, so screen readers announce nothing for them without requiring `aria-hidden`. The caption is real text (`<b>{caption}</b>`) inside the placeholder and is announced normally; `pendingLabel`, when provided, is announced the same way since it too is plain text content.
- **Touch target**: Not applicable; Shot contains no interactive elements.

