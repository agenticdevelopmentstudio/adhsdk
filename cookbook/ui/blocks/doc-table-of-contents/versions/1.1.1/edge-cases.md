
- **Empty headings array**: Component returns null and renders no HTML. This is by design; empty documents have no navigation targets.
- **All headings excluded**: If `excludeIds` excludes every heading in the array, no headings remain and the component returns null.
- **Heading with no matching element**: If a heading's id does not correspond to an element in the DOM (e.g., the heading list includes an id that was not rendered), no scroll occurs and no error is thrown.
- **Very long heading text**: The link renders as a block element with default (`normal`) white-space, inside `<li>`s in the rail's `w-56 overflow-y-auto` aside. The component never truncates the text, and a multi-word heading wraps onto additional lines within the 14 rem width rather than overflowing it. A single unbreakable token long enough to exceed that width still does not spill visibly outside the rail: because the aside already sets `overflow-y: auto`, the browser computes its `overflow-x` as `auto` too, so any such overflow scrolls inside the rail instead.
- **Rapid scroll events**: The active heading is recalculated as the document scrolls, based on `useScrollSpy`'s intersection band (see the scrollspy Design Decision below) rather than which heading is literally closest to the viewport top. If headings are closely spaced the active marker may flip rapidly; no debounce delays the update.
- **Click on active heading**: Clicking an already-active heading scrolls to it again. The smooth-scroll behavior is re-triggered.
- **Custom title is empty or null**: If `title` is an empty string or null, the component still renders the `<h4>` element, but it will be empty.
- **CSS custom properties not defined**: The component uses fallback values only for `--adh-header-height` (3.5rem); other custom properties have no fallbacks. If the theme does not define `--color-accent`, the browser will use the initial (transparent/black) color.
- **Screen resizes from below XL to XL**: Component transitions from hidden to visible. No re-render or data loss occurs; the component's state is preserved.

