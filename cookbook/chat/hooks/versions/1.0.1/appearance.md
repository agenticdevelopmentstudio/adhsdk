
Not applicable — this is a collection of headless React hooks, not a
visual component. They render no JSX and own no DOM node; several read
geometry from (or write a handful of inline style properties/classes onto)
a caller-supplied element, but the actual appearance is entirely the host
component's.

