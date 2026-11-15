
- **Null/empty input**: The empty string, and text with no conflict, MUST
  parse to no document (git-conflict-document-005).
- **Boundary/malformed input**: An unterminated conflict MUST parse to no
  document rather than a partial one (git-conflict-document-005). A marker
  of eight characters, a `=======` with a label, or a marker character
  followed by anything but a space is ordinary text
  (git-conflict-document-006).
- **Empty sides**: An empty ours or theirs is a valid side, and resolving to
  it removes the conflict's lines entirely; a whole resolution of no lines
  is the empty string (git-conflict-document-003).
- **Line endings**: CRLF files parse and resolve with their carriage
  returns intact (git-conflict-document-007); a file without a final
  newline resolves without one (git-conflict-document-004).
- **Custom marker size**: A `conflict-marker-size` attribute other than
  seven is not read; such a file parses as having no conflicts.
