
- **Null or undefined title**: `title` is typed `ReactNode` (not optional) in the prop signature, but the component does not guard against nullish values; see **tolerate-nullish-title**.
- **Empty string kicker**: `kicker=""` is falsy in JavaScript, but the guard tests strictly for `undefined` (`kicker === undefined`), not truthiness, so an empty string still renders the kicker element with empty content. Outcome: `<span class="lp-card__kicker"></span>` appears in the DOM.
- **Null or undefined children**: `children` is typed `ReactNode` (not optional) in the prop signature, but the component does not guard against nullish values; see **tolerate-nullish-children**.
- **Whitespace-only children**: If `children="   "` (whitespace only), it renders as-is; no trimming occurs. Outcome: Whitespace appears as content.
- **Very long title or kicker text**: No line-breaking or truncation is defined at the component level; layout is CSS-driven. Outcome: Text overflows or wraps per the `lp-card` stylesheet rules.
- **Interactive content in title or children**: A consumer MAY place links, buttons, or form fields inside the card. The component MUST NOT prevent or restrict this. Outcome: Interactive elements are rendered and functional.
- **React Fragment as children**: If `children={<>Item 1<span>Item 2</span></>}` (Fragment), React renders the fragment's children directly. Outcome: Both items appear after the title.

