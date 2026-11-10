
**Decision**: Alert detection runs on the source markdown string before parsing, using a fence-aware line classifier to skip fenced lines, rather than searching the rendered output for alert tags.
**Rationale**: Detecting alerts on the rendered string previously failed three ways: a fenced code block that merely documented `[!NOTE]` suppressed every real alert in the document, because the exclusion list keyed on tag text rather than on which lines were fenced; that list was computed once and drifted off its own ranges as the loop shortened the string on each rewrite; and the colored run was delimited by the first paragraph break, which is not a block boundary and painted parts of adjacent blocks such as tables. Running detection on the source, where fencing and quote-line boundaries are still known, eliminates all three failure modes.
**Approved**: pending

**Decision**: Each detected alert is marked in the source with a sentinel pair of private-use Unicode code points (U+E000 and U+E001) surrounding the alert's index, rather than being colored by searching for its label text.
**Rationale**: The sentinel survives the markdown parser as inert text, which lets the color pass locate the exact alert block precisely instead of inferring it from label text. Private-use code points make a collision with author-written content extremely unlikely (see the **Private-use sentinel collision** edge case), but the component does not detect or reject such a collision if one occurs.
**Approved**: pending

**Decision**: A trailing two-space hard break is appended to a blockquote line when the next line is also a blockquote line and the line does not already end in one, and this happens on the source string before parsing.
**Rationale**: The underlying parser renders a single newline inside a block as a soft line break, collapsing it to a space — a rendering choice within what CommonMark's soft-break rule leaves undefined — so an unmodified multi-line blockquote would run its lines together. A trailing two-space hard break is the CommonMark construct the parser instead honors as a literal line break, so inserting it before parsing preserves the original line structure. It is added only on the source, since the rendered string no longer has soft/hard break distinctions to fix.
**Approved**: pending

**Decision**: GFM task-list markers (`[ ]`, `[x]`, `[X]`) are rewritten to Unicode checkbox characters (☐, ☑) on the source string, rather than left for the renderer to interpret.
**Rationale**: The underlying markdown parser treats `[ ]`/`[x]` as literal text inside a list item and has no notion of a task list, so the substitution must happen before parsing for the checkbox glyphs to appear at all. The renderer then treats a rewritten item as an ordinary list item; see **collapse-task-list-bullet** for how the resulting bullet/tab/checkbox sequence is normalized to match other list markers.
**Approved**: pending

**Decision**: Alert labels (NOTE, TIP, IMPORTANT, WARNING, CAUTION) are emitted in English only and are not localized.
**Rationale**: The label is a fixed uppercase of the alert type's case name; no locale or theme parameter is threaded through rendering that a localized label could be resolved from. Localizing would require adding one.
**Approved**: pending

