
- **render-entries**: Component MUST render one entry for each item in the `entries` array.
- **wrap-each-entry**: Component MUST wrap each entry in its own `div` container (the wrapper div, not the `dl`, is the grid item).
- **render-term-and-detail**: Component MUST render the `term` and `detail` of each entry as `dt` and `dd` elements respectively within the entry wrapper.
- **preserve-node-content**: Component MUST accept and render `term` and `detail` as `ReactNode`, preserving inline elements, text, and component structures passed by the caller.
- **use-semantic-markup**: Component MUST wrap all entries in a `dl` (description list) element to encode the statistical relationship.
- **maintain-order**: Component MUST render entries in the order they appear in the `entries` array.

