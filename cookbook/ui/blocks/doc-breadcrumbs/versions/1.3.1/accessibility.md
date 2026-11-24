
- **Role**: Navigation landmark (`<nav>` element)
- **Label**: ARIA label "Breadcrumb" identifies the navigation region
- **Semantic structure**: Uses `<ol>` (ordered list) and `<li>` (list items) for proper document outline
- **Current page indicator**: Last crumb is rendered as plain text (not a link) to indicate it is the current page
- **Link semantics**: All ancestor links use the `LinkComponent` to maintain proper link semantics
- **Keyboard navigation**: All links MUST be keyboard accessible: a native `<a>` element — the default `LinkComponent` — is tabbable and activatable with Enter with no extra work; a custom `LinkComponent` MUST preserve that same native behavior.

