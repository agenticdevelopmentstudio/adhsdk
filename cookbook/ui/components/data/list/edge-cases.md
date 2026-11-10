
- **Empty list**: Rendering `<List />` with no children produces an empty bordered container.
- **Single item**: Rendering a List with one ListItem produces the container with no visible row dividers (dividers appear between rows, not above or below).
- **Nested flex content**: ListItem uses flex layout; when child content includes flex or grid elements, they inherit the flex context.
- **className collision**: If a `className` prop contains a Tailwind class that conflicts with a base class (e.g., `px-6` conflicting with the base `px-3`), `cn()` resolves it with `tailwind-merge`: the caller's class wins and the conflicting base class is dropped, rather than emitting both classes for the CSS cascade to resolve. See **classname-merge** and test vector list-007.

