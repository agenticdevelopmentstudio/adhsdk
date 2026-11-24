
`FileBrowserExclusionState` is a small non-visual model: one boolean,
`hidesExcludedContent`, that says whether a file browser applies the app-wide
Excluded patterns (Settings, File Browser, Excluded) or sets them aside and
shows everything. The patterns themselves live elsewhere; this object is only
the switch that lets a reader see what the patterns hide without editing the
list to do it.

It is a class, not a value, so that one instance can be handed to several
browsers. A project hands the same instance to every one of its browser panes,
so turning the switch off in one pane shows the hidden files in every pane of
that project. A browser built without being given one creates its own instance
with the switch on, so by default excluded content stays hidden.

The object does not persist anything itself. It reports each real change to an
`onChange` callback, which the owner uses to save the answer (the project
owner saves it per project). Use it whenever several file-browser views must
agree on one show-or-hide-excluded choice and some owner must remember the
choice.

