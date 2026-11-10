
- **Container**: Vertical flex container — `.viewport-shell` sets `display: flex; flex-direction: column`.
- **Background**: Transparent (inherits from parent; no background is set)
- **Overflow behavior**: Controlled by `clip` prop — `.viewport-shell` sets `overflow: hidden`; `clip={false}` adds `.vp-shell--open`, which sets `overflow: visible`.
- **Sizing**: `.viewport-shell` sets `height: 100dvh`, filling the visible viewport height.

