
- **Role**: List item containers are semantic `<ul>` or `<ol>` and `<li>` elements, providing correct list semantics to assistive technologies.
- **List role preservation**: The root sets `list-style: none` (see #appearance) without an explicit `role="list"`. Some older WebKit/VoiceOver combinations dropped the implicit list/listitem roles when `list-style: none` was present; current Safari and other major browsers preserve the implicit roles regardless. A consumer targeting older WebKit SHOULD add `role="list"` to the root and `role="listitem"` to each `<li>` at integration time.
- **Ordered list semantics**: When `ordered=true`, the `<ol>` element signals to screen readers that the sequence is ordered. Position announcements (e.g. "item 3 of 7") are common but not universal across screen reader/browser combinations for either `<ol>` or `<ul>`, so content MUST NOT depend on a position announcement for meaning.
- **Unordered list semantics**: When `ordered=false`, the `<ul>` element signals that items are not sequenced.
- **Label requirements**: The component itself has no explicit label; list context is provided by surrounding content or page structure. Each item's `detail` content SHOULD be meaningful and complete on its own, since the component neither truncates nor supplements it.
- **Text content**: Term and detail text are read in sequence; whether bold formatting on the term is announced as emphasis depends on the screen reader and is not guaranteed.
- **No interactive elements**: Points is a static list and does not require focus management, keyboard navigation, or state announcement beyond list semantics.

