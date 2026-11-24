
- **Role**: The breadcrumb section is a navigation landmark (`<nav>` element) with `aria-label` to describe the number and type of paths.
- **Breadcrumb list**: Each trail is a `<ol>` (ordered list) to convey hierarchy structure.
- **Rename button**: Type `button`, has `aria-label="Rename <noun> <node.name>"` to announce the action and the node being renamed.
- **Focus visible**: Rename buttons show `focus-visible:ring-2 focus-visible:ring-apt-gold/40` to provide a visible focus indicator.
- **Chevron separator**: Marked `aria-hidden` because it is decorative and not essential to understanding the structure.
- **Combobox**: Receives `ariaLabel={label}` from the Field's label to identify the control purpose.
- **Entity chooser**: Receives `ariaLabel="Browse <label.toLowerCase()>"` to announce the browsing intent.
- **Semantic structure**: Breadcrumbs use list structure (`<ol>`, `<li>`) to convey hierarchy; this is announced by assistive technology.
- **Label association**: The component is wrapped in a Field that associates the label with the input via `htmlFor` or an external label pattern.
- **Minimum tap target**: The breadcrumb rename buttons are inline text elements (`text-xs`, sized by their content) rather than a discrete tap target of their own; as inline text links they are exempt from the 44×44pt guideline. The Combobox and EntityChooser inputs meet their own minimums independently.

