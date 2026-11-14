
The Unsaved Changes Alert is a modal dialog that blocks interaction and prompts the user before discarding unsaved edits. It is the canonical prompt for all editable surfaces that risk data loss on exit or dismissal. The component enforces consistency by fixing the title ("Discard unsaved changes?") and button labels ("Discard" and "Stay") — only the description text may be customized when the surface can specifically name what is at risk. The component never saves; the user must return to the surface and save there, keeping the component free of persistence dependencies.

