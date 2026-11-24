
- **Empty rows** (MUST): With `rows=[]` the component renders an empty `nav` that still carries its `aria-label`; `useTextLens` finds no matching elements and returns without creating a lens.
- **Single row** (MUST): One row renders one link and no separator, because the separator renders only when `index > 0`.
- **Boundary at 640px** (MUST): At a viewport of 640px or narrower the phone rules apply; at 641px the separators and no column gap apply.
- **Wrapped line** (MUST): Wrapping at desktop width, where separators still show, can leave a `|` at a line end; the component does not detect wrapping, and the phone rule removes separators only below the breakpoint.
- **Duplicate hrefs** (SHOULD): Each fragment is keyed by `row.href`, so two rows with the same href collide on key. The source does not deduplicate; the host SHOULD pass unique hrefs, as `indexRows(page)` does by construction.
- **Empty label or href** (SHOULD): The source does not validate row fields; an empty `label` renders an empty link and an empty `href` renders an anchor to the current page.
- **Lens restart** (MUST): The lens hook keeps a `swept` flag. If its effect re-runs after the first sweep (an option or the ref changes), the new lens starts with a 0 ms delay instead of 2000 ms, so the delay applies only to the first sweep.
- **Unmount before the delay** (MUST): The hook clears its timer and destroys the lens on cleanup, so unmounting within the first 2000 ms starts no sweep.
- **Reduced motion** (MUST): With `prefers-reduced-motion: reduce`, the lens `start` is a no-op and links stay in their resting colour.
- **JavaScript disabled** (MUST): The anchors, labels and hrefs render and work; only the sweep is lost.
- **Concurrent access**: Not applicable: the component is a stateless render with one ref, and no shared mutable state is touched by more than one caller.
- **Offline or disconnected**: Not applicable: the component makes no network request; the anchors navigate as the browser does.
- **Server rendering**: The source marks the file `'use client'` and ships it from the client barrel only; the nav markup itself is plain, and the lens starts only in an effect.

