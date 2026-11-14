
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-metadata-001 | empty-renders-nothing | `{ fields: [] }` | Component returns `null` and renders no DOM element |
| doc-metadata-002 | dl-root | `{ fields: [{ label: "Status", value: "active" }] }` | Renders `<dl>` element in the DOM |
| doc-metadata-003 | label-value-pairs | `{ fields: [{ label: "Version", value: "1.0.0" }] }` | Renders `<dt>` containing "Version" and `<dd>` containing "1.0.0" |
| doc-metadata-004 | array-values-wrap | `{ fields: [{ label: "Tags", value: ["ui", "form"] }] }` | Renders a `<span>` whose class list includes `flex flex-wrap justify-end gap-x-3` and which has two child items |
| doc-metadata-005 | scalar-values-direct | `{ fields: [{ label: "Author", value: "Jane Doe" }] }` | Value "Jane Doe" renders directly in `<dd>` without additional wrapper |
| doc-metadata-006 | style-override-merge | `{ fields: [{ label: "Status", value: "active" }], className: "custom-class" }` | `<dl>` element includes both default classes and "custom-class" |
| doc-metadata-007 | attribute-passthrough | `{ fields: [{ label: "Status", value: "active" }], "data-testid": "metadata", id: "doc-meta" }` | `<dl>` element has `data-testid="metadata"` and `id="doc-meta"` attributes |
| doc-metadata-008 | field-order | `{ fields: [{ label: "A", value: "1" }, { label: "B", value: "2" }, { label: "C", value: "3" }] }` | Three rows render in the order A, B, C |
| doc-metadata-009 | style-override-merge | `{ fields: [{ label: "Status", value: "active" }], className: "mb-0" }` | `<dl>` class list contains `mb-0` and not `mb-6` |
| doc-metadata-010 | scalar-values-direct | `{ fields: [{ label: "Owner", value: null }] }` | Renders a `<dt>` "Owner" and an empty `<dd>`; no error is thrown |
| doc-metadata-011 | label-value-pairs | `{ fields: [{ label: <em>Status</em>, value: "active" }] }` | The `<dt>` contains an `<em>` element with "Status" |
| doc-metadata-012 | array-values-wrap | `{ fields: [{ label: "Tags", value: ["ui", "form"] }] }` | Rendering produces no React key warning on the console |
