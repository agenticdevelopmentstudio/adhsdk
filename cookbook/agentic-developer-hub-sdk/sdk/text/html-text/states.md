
Not applicable — this is a stateless conversion enum, not a visual component. Within one call the writer tracks preformatted depth, whether it is at the start of a `<pre>`, and whether the last preformatted scalar was a carriage return; none persists between calls.

