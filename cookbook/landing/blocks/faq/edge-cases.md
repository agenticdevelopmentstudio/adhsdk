
- **Empty entries array**: Component MUST render without error. Output is a single `<div class="lp-faq"></div>` with no children.
- **Null or undefined entries**: Not applicable. The prop type is `FaqEntry[]`; null/undefined assignment is a type violation, not a runtime edge case the component handles.
- **Null or undefined question/answer**: React will render `null` or `undefined` as nothing (empty space). If this is undesirable, the caller MUST validate entries before passing to the component.
- **Very long question or answer**: No constraint in source. Content renders as-is; CSS is responsible for text wrapping and overflow handling.
- **Special characters or HTML in question/answer**: Behavior depends on the input type. If `question` is a string, HTML characters are rendered as text (safe). If `question` is a component containing HTML, that HTML renders as intended. No HTML sanitization is performed by the component.
- **Multiple entries with open: true**: All MUST start expanded. Browser allows multiple `<details>` elements to be open simultaneously (unlike a single-open accordion — see [adhsdk.ingredient.ui.components.layout.accordion](cookbook:85ce8c4b-5233-48af-9268-30cddd4747f9)); behavior matches the source design.
- **Key collisions**: Entries are keyed by array index (`key={i}` in the source). If the entries array is mutated (items reordered or removed), React will reuse DOM nodes by index, which may cause state mismatches. This is a known limitation of index-based keying; the component does not validate or warn about it, and the source has no `id` field to key by instead — see **index-based-keying** under Design Decisions.
- **Re-render with changed open**: See **initial-open-state**. A re-render that changes `entries[i].open` overrides the user's own toggle for that entry; a re-render that leaves the value unchanged does not touch the browser's live state. See #test-vectors/faq-008 and #test-vectors/faq-009.

