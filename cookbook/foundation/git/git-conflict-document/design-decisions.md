
**Decision**: Unterminated conflicts and conflict-free text parse to no
document rather than a document of common text.
**Rationale**: A caller offering per-conflict choices needs to know the file
is something it can resolve; a partial parse of a damaged file would let it
write back text with a dangling marker.
**Approved**: yes

**Decision**: Marker-like lines where no marker is expected are text, not
errors.
**Rationale**: Files legitimately contain `=======` (Markdown headings, ASCII
rules), and git itself only writes a nested `<<<<<<<` inside a side when the
file already held one; treating them as text matches what git wrote.
**Approved**: yes

**Decision**: The document is separate from the git client.
**Rationale**: It is pure text processing with no process to spawn, so it
is testable without a repository and usable by any caller that already has
the file's text.
**Approved**: yes
