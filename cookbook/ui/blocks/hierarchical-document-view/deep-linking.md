
`DocNav`'s `NavHeadings` writes a linkable position: clicking a heading link
while its own page is already open calls `event.preventDefault()`, scrolls to
`document.getElementById(heading.id)`, and then
`window.history.replaceState(null, "", href)` so the `#id` hash lands in the
address bar; from any other page the same link is an ordinary navigation
through `LinkComponent`. `DocTableOfContents` renders real `href="#${id}"`
anchors (so a reader can right-click one to copy or open in a new tab), but its
click handler only `preventDefault()`s and smooth-scrolls — it never calls
`history.replaceState`, so following a rail entry does not update the visible
URL. `useScrollSpy` tracks the reader's current heading with an
`IntersectionObserver` for the rail's marker, but does not itself write
anything to the URL. HDV holds no route state of its own: `activePath` arrives
as a plain string prop from the host's own router subscription (see
`doc-types.ts`), and no component here reads `window.location` to restore a
hash-linked position on mount.

