
### Parsing

- **conflict-markers**: A marker MUST be exactly seven of its character
  (`<`, `|`, `=`, `>`) at the start of a line, followed by the end of the
  line or a space and a label. `=======` MUST take no label: anything after
  it makes the line ordinary text. Eight or more of the character is
  ordinary text.
- **conflict-structure**: A conflict MUST open with `<<<<<<<` in common
  text, hold the ours lines, optionally `|||||||` and the base lines, then
  `=======` and the theirs lines, and close with `>>>>>>>`. The labels after
  the opening and closing markers MUST be kept verbatim, spaces included,
  and are empty when the marker has none.
- **conflict-diff3-base**: A conflict with a `|||||||` section MUST carry
  its base lines; one without MUST carry no base, which is distinct from an
  empty base.
- **conflict-lookalikes**: Marker-like text where no marker is expected
  MUST be ordinary text: a `=======`, `|||||||` or `>>>>>>>` in common text,
  a second `<<<<<<<` inside a conflict, a `|||||||` inside theirs.
- **conflict-crlf**: Lines MUST split on line feed only; a carriage return
  before it stays part of the line, and MUST be ignored when reading a
  marker, so a CRLF file still parses and its resolution keeps its CRLF
  lines.
- **conflict-trailing-newline**: Whether the text ended with a line feed
  MUST be recorded, so the resolved text ends the same way.
- **conflict-no-document**: Text holding no conflict, and text with a
  conflict that is never closed, MUST parse to no document.

### Resolving

- **conflict-resolve-choices**: Resolving MUST replace conflict `n`
  (counting from zero, in order) with `choices[n]`: ours, theirs, ours then
  theirs, theirs then ours, or the base; common runs are kept as they are.
- **conflict-resolve-incomplete**: Resolving MUST produce nothing while any
  conflict has no choice, or when a conflict chosen as base has no base
  section.
- **conflict-resolve-empty**: A resolution with no lines at all MUST be the
  empty string, with no trailing line feed added.
