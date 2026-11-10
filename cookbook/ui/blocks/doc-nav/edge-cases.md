
- **Empty children array**: If `node.children` is undefined or empty array, node is treated as a leaf; no branch or heading sub-list renders.
- **No headings**: If `node.headings` is undefined or empty array, NavHeadings returns null and no heading sub-list renders.
- **Heading element not found**: If `document.getElementById(heading.id)` returns null when scrolling, the scroll is skipped and hash is not set; link click event is still prevented.
- **Active path not in tree**: If `activePath` does not match any node `href`, no links styled as selected; section expansion state still initialized based on prefix matches.
- **Circular or malformed tree**: Component does not validate tree structure; if a node's href appears as a prefix of itself (invalid) or circular parent-child relationships exist, behavior is undefined; tree MUST be acyclic and well-formed by the host.
- **Very deep nesting**: No hard depth limit; rendering cost scales with tree size and React reconciliation, same as any other recursive component of this shape.
- **Drawer open at `lg` breakpoint**: Desktop nav is `hidden lg:block`; drawer renders at all breakpoints; both rendering simultaneously with `open=true` at `lg+` creates duplicate nav in DOM but only drawer is visible to user.
- **Route change during scroll**: If `activePath` changes while `element.scrollIntoView()` is in progress, the scroll completes but may scroll to an element that is no longer "on page" in the component's view (rare edge case, depends on timing).
- **Missing active page headings**: If `activePath` matches a node but the node has no `headings` array, component renders the leaf link without heading sub-list; this is correct behavior.

