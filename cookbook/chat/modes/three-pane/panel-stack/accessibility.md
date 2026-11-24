
The root `div` carries no ARIA role: PanelStack does not identify the stack as a landmark or a group to assistive technology, and it delegates all content semantics to the DetailPane children it renders (see Compliance: `semantic-markup`). PanelStack does not manage focus — it neither traps, moves, nor restores focus when `visibleTopicIndexes` changes and panes mount or unmount; the browser's default focus handling applies as elements enter and leave the DOM.

