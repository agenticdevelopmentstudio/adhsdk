
- **Missing or null title**: `title` is a required prop; omitting the key entirely is a compile-time TypeScript error. An explicit `null` or `undefined` value is permitted by the `ReactNode` type (which includes both) and renders as an empty heading — nothing renders inside the h3.
- **Empty title**: Title is rendered as provided; an empty string produces an empty h3.
- **Empty lede value**: If `lede` is defined as an empty value (e.g. an empty string), a paragraph still renders — see **render-optional-lede**. Callers should omit `lede` entirely to avoid an empty paragraph.
- **Empty points array**: If `points` is defined as an empty array, no list renders — see **render-optional-points**.
- **Single point**: `points: ["Only one"]` renders a list with one item.
- **Very long content**: Component imposes no length limits; overflow is handled by CSS or the parent container.
- **Rich content in lede or points**: `lede` and each point accept arbitrary content, not just plain text — inline formatting or nested elements are supported wherever the platform's content-value type allows it.
- **Missing "us" or "them" prop**: Both `them` and `us` are required; omitting either is a compile-time TypeScript error.
- **Right-to-left locale**: Rendering order is unaffected by text direction — see **fixed-side-order**. The component provides no RTL-specific layout adaptation.

