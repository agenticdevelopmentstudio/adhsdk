
- **flipped-origin**: The view MUST report a flipped coordinate system, so its origin is the top-left corner and y grows downward.
- **content-at-top**: Inside a scroll view, a document of this view whose content is shorter than the visible area MUST sit at the top of the visible area, with the slack below.
- **no-drawing**: The view MUST NOT draw anything of its own.
- **container-only**: The view MUST NOT add layout, subviews or behavior of its own; owners add their content and constraints.
- **not-subclassable**: The type MUST be final.
- **public**: The type MUST be public so other frameworks can use it as a document view.

