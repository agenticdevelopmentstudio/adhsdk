
- **Empty entries array**: Component renders an empty list container. Expected behavior: list is rendered but contains no items.
- **Null or undefined term property**: When term is undefined, no term text or spacing is rendered. Expected behavior: detail text appears without preceding bold text.
- **ReactNode as term or detail**: Both `term` and `detail` accept ReactNode (can be strings, elements, fragments). Expected behavior: ReactNode is rendered as-is within the wrapper structure.
- **Very long term or detail text**: No truncation occurs in the component; wrapping and overflow are delegated to CSS. Expected behavior: text flows according to CSS rules.
- **Empty detail text**: An entry with empty string or empty ReactNode as detail renders an empty span. Expected behavior: `<li><span></span></li>` for that entry.

