
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
