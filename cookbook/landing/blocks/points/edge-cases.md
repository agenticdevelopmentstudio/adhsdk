
- **Empty entries array**: Component renders an empty list container. Expected behavior: list is rendered but contains no items.
- **Undefined term property**: When term is `undefined` or absent, no term text or spacing is rendered. Expected behavior: detail text appears without preceding bold text.
- **Null, empty-string or zero term**: Only `undefined` counts as absent. `term: null` renders `<b></b>` followed by a space, `term: ""` the same, and `term: 0` renders `<b>0</b>` followed by a space (see **term-omission**, points-012).
- **ReactNode as term or detail**: Both `term` and `detail` accept ReactNode (can be strings, elements, fragments). Expected behavior: ReactNode is rendered as-is within the wrapper structure.
- **Very long term or detail text**: No truncation occurs in the component; wrapping and overflow are delegated to CSS. Expected behavior: text flows according to CSS rules.
- **Empty detail text**: An entry with empty string or empty ReactNode as detail renders an empty span. Expected behavior: `<li><span></span></li>` for that entry.

