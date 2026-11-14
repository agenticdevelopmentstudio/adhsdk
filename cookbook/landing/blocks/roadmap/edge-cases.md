
- **Undefined eyebrow**: When eyebrow is `undefined` (or the prop is omitted), no `.lp-eyebrow` span is rendered — see **eyebrow-omitted-when-absent**. This prevents empty markup and unwanted spacing caused by an empty `<span className="lp-eyebrow"></span>`.
- **Null eyebrow**: When eyebrow is `null`, the span is still rendered — see **eyebrow-present** — because `null` is not `undefined`. React displays no visible content for a `null` child, so the span appears empty but is present in the markup.
- **Empty-string eyebrow**: When eyebrow is `""`, the span is rendered — see **eyebrow-present** — with no visible text content, but the span element and its styling still occupy markup.
- **Falsy non-undefined eyebrow (e.g. `false`, `0`)**: Same as `null` and `""` — any value other than `undefined` renders the span per **eyebrow-present**; only `undefined` triggers omission.
- **Multiple or complex children**: Component renders all children as-is; no validation or transformation is applied.
- **No children**: `children` is a required prop, but its `ReactNode` type admits `null` and `undefined`. Passing one renders the container and optional eyebrow with no child content inside (roadmap-009).

