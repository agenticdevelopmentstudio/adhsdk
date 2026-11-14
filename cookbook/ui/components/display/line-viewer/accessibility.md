
- The scroll view carries the viewer's accessibility identifier (`init(identifier:)`); the document view carries `<identifier>.text`.
- The document view is an accessibility element with role `textArea`, read-only, whose `accessibilityValue` is the text of the rows currently visible, joined by `\n`.
- Colour is never the only signal: diff rows also carry their gutter values, and folded headers draw a chevron.

