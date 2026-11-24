
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-metadata-001 | empty-renders-nothing | `{ fields: [] }` | Component returns `null` and renders no DOM element |
| doc-metadata-002 | dl-root | `{ fields: [{ label: "Status", value: "active" }] }` | Renders `<dl>` element in the DOM |
| doc-metadata-003 | label-value-pairs | `{ fields: [{ label: "Version", value: "1.0.0" }] }` | Renders `<dt>` containing "Version" and `<dd>` containing "1.0.0" |
| doc-metadata-004 | array-values-wrap | `{ fields: [{ label: "Tags", value: ["ui", "form"] }] }` | Renders `<span>` with flex layout containing two items right-aligned with 3 (12px) horizontal gap |
| doc-metadata-005 | scalar-values-direct | `{ fields: [{ label: "Author", value: "Jane Doe" }] }` | Value "Jane Doe" renders directly in `<dd>` without additional wrapper |
| doc-metadata-006 | style-override-merge | `{ fields: [{ label: "Status", value: "active" }], className: "custom-class" }` | `<dl>` element includes both default classes and "custom-class" |
| doc-metadata-007 | attribute-passthrough | `{ fields: [{ label: "Status", value: "active" }], "data-testid": "metadata", id: "doc-meta" }` | `<dl>` element has `data-testid="metadata"` and `id="doc-meta"` attributes |

