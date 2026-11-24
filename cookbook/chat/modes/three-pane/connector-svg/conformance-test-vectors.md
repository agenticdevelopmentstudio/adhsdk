
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| connector-001 | svg-root, aria-hidden | container reference to a valid container, pairs = [{from: "el1", to: "el2"}], both elements registered | SVG with class "pc-connector-svg" and aria-hidden="true", containing one connector |
| connector-002 | connector-pairs, element-resolution, line-endpoints | container reference, pairs = [{from: "el1", to: "el2"}], both elements registered | One line drawn from center of el1 to center of el2 |
| connector-003 | unresolved-pair-omission | container reference, pairs = [{from: "el1", to: "missing"}] | Zero lines and zero circles rendered for that pair |
| connector-004 | endpoint-circles, circle-radius | container reference, pairs = [{from: "el1", to: "el2"}] | Two circles (r=3) rendered, one at each line endpoint |
| connector-005 | source-color | container reference, source element has computed color = "#ff0000", pairs = [{from: "el1", to: "el2"}] | Line rendered with stroke "#ff0000"; both endpoint circles rendered with fill "#ff0000" |
| connector-006 | center-coordinates, container-reference | container reference at (100, 200), element at (150, 250) with width=100 height=50 | Line endpoint for that element computed at (100, 75) relative to container reference origin |
| connector-007 | resize-observer-updates | container reference, one element resizes from 100×50 to 200×100 | Line endpoints redrawn to new center positions |
| connector-008 | raf-batching | Rapid resize events fire in succession | Only one recomputation occurs via single requestAnimationFrame call |
| connector-009 | raf-cancellation | requestAnimationFrame scheduled, component unmounts before frame executes | `cancelAnimationFrame` is called with the pending frame handle |
| connector-010 | window-resize-updates | container reference, window resize event fires | Connector positions are recomputed |
| connector-011 | scroll-updates | container reference, scroll event fires on any element (an ancestor or not), observed by the capture-phase window listener | Connector positions are recomputed |
| connector-012 | teardown | Component unmounts | ResizeObserver is disconnected; window resize and scroll listeners are removed |
| connector-013 | null-container-ref | Container reference resolves to `null` | No computation occurs; SVG renders with no lines or circles |
| connector-014 | empty-pairs | pairs = [] | SVG renders with no lines or circles |
| connector-015 | recompute-on-input-change | pairs prop changes from [{from: "el1", to: "el2"}] to [{from: "el1", to: "el3"}], or the registry snapshot adds "el3" | ResizeObserver is re-established for the new tracked set (the container plus every registered element, including el1 and el3) and geometry is recomputed for the new pairs |
| connector-016 | stroke-width, connector-opacity | container reference, pairs = [{from: "el1", to: "el2"}] | Line rendered with strokeWidth=1 and strokeOpacity=0.4; both endpoint circles rendered with fillOpacity=0.4 |
| connector-017 | center-coordinates | frame at (0, 0), element with width=0 height=0 at (50, 50) | Center computed as (50, 50); connector line still renders using that point as an endpoint |
| connector-018 | duplicate-and-degenerate-pairs | container reference, pairs = [{from: "el1", to: "el1"}, {from: "el1", to: "el2"}, {from: "el1", to: "el2"}], all registered | Three lines render: one zero-length line with both circles at el1's center, and two identical lines for el1 to el2 |
