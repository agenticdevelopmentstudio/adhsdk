
- **Title bar**: Hidden (`.titleVisibility = .hidden`, `titlebarAppearsTransparent = true`)
- **Background**: Transparent (`.isOpaque = false`, `backgroundColor = .clear`)
- **Drag handle**: Window background (movable by window background; `.isMovableByWindowBackground = true`)
- **Default window size**: See `contentSize` under **Configuration** below (`ChatWindowConfiguration`'s default)
- **Gear/appearance control**: Trailing edge, managed by `ChatWindowAppearanceController`
- **Chat view**: Fills window content area, respects theme alpha and styling

