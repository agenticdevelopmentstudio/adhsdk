---
id: b28294a3-4eba-4c42-a7e9-d50821ed8f75
title: "Git Conflict Document"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-15
modified: 2026-11-15
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A conflicted file's text read into common runs and conflicts (ours, an optional diff3 base, theirs) from git's seven-character markers, and resolved per conflict by a choice of side."
platforms:
  - swift
  - macos
tags:
  - git
  - version-control
  - merge
  - conflicts
  - parsing
depends-on: []
related:
  - 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
references:
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitConflict.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitConflictTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---
# Git Conflict Document
## Overview

The git conflict document reads the text git leaves in a conflicted working
file and turns it into an ordered list of segments: runs of common lines,
and between them each conflict with its two sides (ours, then theirs), the
base when the merge used `merge.conflictStyle=diff3` or `zdiff3`, and the
labels git wrote on the opening and closing markers. Given a choice for
every conflict (ours, theirs, ours then theirs, theirs then ours, or the
base) it produces the resolved text, which a caller writes back to the
working file and stages. It is pure: no file access, no git process, no
state beyond the parsed value. The git client spawns git; this document only
reads and writes text.
## Behavioral Requirements

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
## Appearance
Not applicable — this is a headless text parser, not a visual
component.
## States
Not applicable — this is a headless text parser, not a visual
component.
## Accessibility
Not applicable — this is a headless text parser, not a visual
component.
## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-conflict-document-001 | conflict-structure | Parse `top`, a conflict `HEAD`/`ours one`/`theirs one`/`topic`, `middle`, a second such conflict, `bottom`, with a trailing newline. | Five segments: common `top`, the first conflict with labels `HEAD` and `topic`, common `middle`, the second conflict, common `bottom`; two conflicts; ends with a newline. |
| git-conflict-document-002 | conflict-diff3-base, conflict-structure | Parse `<<<<<<< HEAD:a.txt`, `ours`, `\|\|\|\|\|\|\| merged common ancestors`, `base 1`, `base 2`, `=======`, `theirs`, `>>>>>>> feature branch`. | One conflict with base `base 1`, `base 2`, labels `HEAD:a.txt` and `feature branch`; resolved to base gives `base 1\nbase 2\n`. |
| git-conflict-document-003 | conflict-markers, conflict-resolve-empty | Parse `<<<<<<<`, `=======`, `theirs`, `>>>>>>>`. | One conflict with empty ours, no base and empty labels; resolved to ours gives the empty string; to theirs gives `theirs\n`. |
| git-conflict-document-004 | conflict-trailing-newline | Parse `a`, a conflict `x`/`o`/`t`/`y`, `z` with no trailing newline; resolve to theirs. | Not ending with a newline; resolved text is `a\nt\nz`. |
| git-conflict-document-005 | conflict-no-document | Parse a conflict with no closing marker; one with neither separator nor closing marker; plain text; the empty string. | Each is no document. |
| git-conflict-document-006 | conflict-lookalikes, conflict-markers | Parse `=======`, `<<<<<<<< eight`, `<<<<<<< HEAD`, `<<<<<<< inner`, `=======`, `t`, `>>>>>>> x`, `>>>>>>> after`. | Common `=======`, `<<<<<<<< eight`; a conflict with ours `<<<<<<< inner` and theirs `t`; common `>>>>>>> after`. |
| git-conflict-document-007 | conflict-crlf | Parse `a\r\n<<<<<<< o\r\nx\r\n=======\r\ny\r\n>>>>>>> t\r\n`; resolve to ours. | Ends with a newline; resolved text is `a\r\nx\r\n`. |
| git-conflict-document-008 | conflict-resolve-choices | The two-conflict text of 001 resolved with the same choice for both, for each of ours, theirs, ours then theirs, theirs then ours; and with ours then theirs per conflict. | The common lines kept, each conflict replaced by the chosen lines in the chosen order. |
| git-conflict-document-009 | conflict-resolve-incomplete | The text of 001 resolved with a choice for conflict 0 only, with no choices, and with base for a conflict that has no base. | Nothing, in each case. |
| git-conflict-document-010 | conflict-resolve-choices | A real two-conflict merge in a temporary repository, the working file resolved to ours for every conflict. | Equal to the file at index stage 2 (`git show :2:a.txt`), which is our branch's file. |
## Edge Cases

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
## Configuration
Not applicable: the document has no options. The marker length is fixed at git's default of
seven.
## Deep Linking
Not applicable: the document is a pure text parser with no URL scheme or
activity handoff of its own.
## Localization
Not applicable: the document produces no user-facing strings; it returns
the file's own text.
## Accessibility Options
Not applicable: the document renders no UI and defines no display
options.
## Feature Flags
Not applicable: no part of this component defines or reads a feature-flag
key.
## Analytics
Not applicable: no part of this component emits an analytics or telemetry
event.
## Privacy

- **Data collected**: None. The document holds the text of one working file
  in memory for as long as the caller keeps it, and persists nothing.
- **Logging**: The document logs nothing, so file contents never reach a
  log.
## Logging
Not applicable: the document logs nothing. File contents are user data and
are never logged.
## Platform Notes

- **Swift**: A `Sendable`, `Hashable` value type in the Foundation-only Core
  framework, with a static `parse(_:)` returning an optional document and
  `resolved(_:)` taking a dictionary from conflict index to choice. Lines
  are split with `components(separatedBy: "\n")`, which works on UTF-16
  code units, so a `"\r\n"` line keeps its carriage return. Only the
  trailing-newline check looks at Unicode scalars, because `"\r\n"` is a
  single `Character` in Swift and a character-level suffix check would miss
  it.
- **Other platforms**: Split on the line-feed byte or code point, never on a
  platform line-ending abstraction that would swallow the carriage return.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitConflict.swift` | confirmed (1.0.0) |

## Design Decisions

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
## Compliance
Not yet assessed.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-15 | Mike Fullerton | Initial creation: seven-character markers, an optional diff3 base, lookalikes as text, CRLF lines, the trailing-newline rule, no document for an unterminated conflict or none, and resolution by a choice per conflict. Platform note: lines split on "\n" by UTF-16 code unit; only the trailing-newline check is by scalar. |
