
The `text` prop's content is caller-supplied; translating it is the content provider's responsibility, not this component's. The component does not set `dir` or `direction`, so in a right-to-left locale the `<pre>` inherits right-to-left directionality from its ancestor. That can mirror the block's alignment and reorder bidi-neutral characters within literal text such as shell commands or config fragments — the source does not force left-to-right layout for this content. See **rtl-layout-support** in Compliance.

