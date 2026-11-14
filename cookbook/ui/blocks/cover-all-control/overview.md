
Cover All Control is a small segmented control of two icon buttons set in one bordered frame. The left button, drawn as three left-pointing chevrons (`<<<`), collapses every list in a stack of lists; the right button, three right-pointing chevrons (`>>>`), expands them all. It is used by the hierarchical topic detail and hierarchical menu detail layouts, which show a stack of lists side by side and let the user cover (collapse) a list to a narrow strip.

The control decides nothing about the stack. The host passes `canCollapse` and `canExpand`, and the control disables a half when its flag is false. The source states the rule the host follows: each half is enabled only when pressing it would visibly change the stack, so a half that could do nothing is shown disabled rather than hidden.

