
This component is the application's **Browser** menu: a top-level menu,
placed after View, that gathers the commands a person uses on a web page —
reload it, stop loading it, go back, go forward — together with opening the
History window and showing or hiding the current pane's privacy toolbar.
It is contributed by the web browser windows feature, not written into the
host's menu bar, so the host only reserves the menu's place.

Every page command acts on one target: the browser pane in the key window.
When the key window holds no browser pane the page commands disable rather
than act on a pane in some other window. Back and Forward are also entries
in the Keyboard Shortcuts registry, under a "Web Browser" section, so a
person can rebind them; the menu items' displayed key equivalents follow
whatever the registry currently binds, through a small bridge between a
menu item and a registered key command. Reload and Stop keep fixed keys.

The design is written before the code (design-first, from the more privacy
features design, section 1.2, and its phase 1 plan, Task 3).

