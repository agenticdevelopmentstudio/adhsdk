
**Decision**: The pane, not the host, owns the layout of the bar and the body, with the bar flush and only the body padded.
**Rationale**: The source comment says this is "the whole point of the pane": a host renders it with no padding, so no host can wrap the bar in padding by mistake.
**Approved**: pending

**Decision**: The bar stays visible after the document stops being editable while a draft is dirty or a conflict is pending.
**Rationale**: The source comment gives the reason: Cancel and Reload theirs must stay within reach, or an author could be left with an unsaved draft they cannot discard.
**Approved**: pending

**Decision**: The editor is not rendered until `document.value` is not null; the body stays empty rather than showing a placeholder.
**Rationale**: The prop documentation says "Until its `value` loads the pane shows its body empty." Hosts show their own loading state through the children or `MarkdownDocumentPaneBody`.
**Approved**: pending

**Decision**: `value`, `onChange` and `readOnly` are omitted from the pane's props and derived from `document` and `editable`.
**Rationale**: The type extends the editor's props with those three omitted, so the pane stays the single place that wires the document to the editor and a host cannot pass a value that disagrees with the document.
**Approved**: pending

**Decision**: `MarkdownDocumentPaneBody` is exported separately.
**Rationale**: The source comment says it is for a host "showing something in the pane's place (loading, not found, an error) so it lines up with the loaded pane."
**Approved**: pending

