
A window's title with an icon before it, set at the leading edge of the title
bar just after the window controls, the way a pane's title bar shows its icon
and name. It replaces the window's own centred title, which the platform draws
without an icon. The window's `title` property still carries the name, for the
Window menu and for accessibility, but it is no longer drawn.

The component is a leading titlebar accessory. It owns an icon (14 points
square) and a single-line label in a horizontal stack, sizes itself to the
title's own width, and never takes more width than the window leaves once room
is kept for trailing accessories (such as a settings gear) and the window
controls. A long title truncates at its tail rather than running under them.

Use it in any window that wants an icon beside its title in the title bar.

