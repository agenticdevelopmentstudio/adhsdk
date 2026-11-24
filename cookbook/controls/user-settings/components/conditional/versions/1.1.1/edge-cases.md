
- **Null children** (see **null-children-renders-nothing**): When `children` is `null` or `undefined` and `when` is `true`, the component renders nothing.
- **Falsy children values** (see **falsy-children-renders-value**): When `children` is a falsy value such as `0`, `false`, or an empty string and `when` is `true`, the component renders that value as React normally would.
- **Empty fallback** (see **fallback-defaults-to-null**): When `when` is `false` and `fallback` is not provided, the component renders nothing.
- **Mixed and array children** (see **mixed-children-render-in-order** and **no-wrapper-element**): When `children` is an array or contains mixed content (strings, elements, fragments) and `when` is `true`, all content renders in order without an added wrapper.
- **Toggling `when` at runtime** (see **inactive-branch-not-mounted**): Switching `when` unmounts the previous branch and mounts the new one only when the outgoing and incoming branches are elements of different types (or differently keyed). Because both branches render into a single unkeyed slot, toggling between two elements of the *same* type reconciles the existing instance in place instead — its state (and any effects) survive the toggle rather than being discarded.

