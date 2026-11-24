
A vertical (top/bottom) split with a draggable divider and a collapse toggle for the bottom pane, in `@adh-sdk/ui`. It lays out two stacked panes — PEERS in the column; the bottom never overlays the top — whose split ratio the user drags; the bottom pane can be collapsed/expanded via a chevron on the divider, with an animated boundary. It offers controlled collapse plus an optional persisted ratio, and is otherwise self-contained.

The divider has two forms:

- **seam** (default): a 1px connected boundary with a visible centered grip pill and a generous 24px transparent grab band; the collapse chevron sits at the right edge.
- **header bar** (`header`/`headerActions` set): the divider IS the bottom pane's header — a real strip with the pane's title left, optional actions and the disclosure chevron at the far right. The whole bar is a drag target, and the bar stays visible while the pane is hidden (it is the collapsed remnant).

It adapts the hand-rolled divider in `status-backend`'s `Dashboard.tsx` (ratio state, `row-resize`, clamp, localStorage persistence) into a reusable, token-styled component. It is used by `ListWithDetailsPane` (table over details).

