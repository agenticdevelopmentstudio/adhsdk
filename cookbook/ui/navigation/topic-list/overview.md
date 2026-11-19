
This is a reusable, domain-agnostic component that renders a sectioned,
single-selection sidebar list. It is "a reusable list with optional
section headers, icon-friendly rows, and closure-based selection," and it
knows nothing about settings, the host app, or any specific data domain. A
caller supplies rows through a flat-list setter (no section headers) or a
grouped setter (sections, each optionally titled) and observes the user's
selection through a selection callback.

A caller extends the component through closure and provider seams rather
than by subclassing it: the selection callback, the item-menu and
header-menu providers, the double-click callback, the drag-payload
provider, the drop validator and the drop callback, plus the title,
header accessory and footer setters. A caller that holds an instance and
sets these gets every behavior here. The component is also open to
subclassing, and one consumer subclasses it to back the sidebar of a split
view ([adhsdk.ingredient.ui.settings.settings-panel-list](cookbook:a41760b2-4ffd-413b-970f-c0373c9bd3b6));
see Design Decisions.

Beyond the list itself, the component owns an optional title header (shown
above the list, with an optional client accessory view such as a search
field beneath the title) and an optional client footer view pinned below
the list - both collapse to zero height when unset. The whole view
repaints itself on every theme change.

Two distinct "header" concepts are kept separate throughout this ingredient:
the component's own title header (the custom title + accessory area above
the list) and the list's own built-in column header row, which this
component always disables. A section's optional title renders as a
**group header row** inside the list itself - a third, unrelated use of
"header."

