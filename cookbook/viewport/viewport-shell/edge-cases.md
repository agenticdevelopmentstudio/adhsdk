
- **Null children**: Covered by **render-children** (viewport-010).
- **Empty children array**: Covered by **render-children** (viewport-011).
- **Multiple children**: Covered by **render-children** (viewport-012).
- **clip prop is undefined**: Covered by **clip-prop** (viewport-006).
- **Rapid clip prop changes**: When `clip` changes between `true` and `false` across renders, the component MUST update its class list and computed overflow synchronously, and MUST preserve `children` without remounting them.

