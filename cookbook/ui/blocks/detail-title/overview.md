
The Detail Title moves a detail pane's title out of the pane and into the strip that sits atop its stack's detail (the hierarchical topic/document/menu stacks). The stack owns a slot element in that strip; shared title drawers (a feature title, a button bar's title, a pane-title section header, a coming-soon pane) hand their title to the slot instead of drawing it inline. The module has two sides. The stack side is `useDetailTitleHost`, `DetailTitleProvider`, `DetailTitleSuppressed`, `detailStripTitle` and `useSelectedTopicLabel`. The pane side is `useDetailTitle`.

The transport is a portal, not a published value: a pane registers only its id, and its title node is portalled into the slot. This lets any node be a title, because a node is a new object every render and an effect keyed on one would re-publish forever. One title shows at a time; when several are registered the last to register wins and the others draw inline.

