
ChatWindowController is an AppKit window controller that presents a chat interface in a floating window. The window has no title bar, uses a transparent background to respect the theme's alpha values, and provides appearance controls (text size, transparency, optional backdrop animation) via a gear icon at the trailing edge. It manages window frame persistence, input focus, and integrates with a host application's chat view model and backend. Subclass it to add host-specific behavior such as connection rituals or status items.

