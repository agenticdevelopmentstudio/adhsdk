
- **Empty category options list**: When `category.options` is an empty array, `CategoryField` receives it and determines rendering behavior; this component does not filter or default it.
- **Empty tags options list**: When `tags.options` is an empty array, `TagSetField` receives it and determines rendering behavior; this component does not filter or default it.
- **Empty category value**: When `category.value=""` (empty string), the component passes it through as-is; no category is selected.
- **Empty tags value array**: When `tags.value=[]` (empty array), no tags are selected; the component passes it through as-is.
- **Missing category.nodes**: When `category.nodes` is undefined or omitted, `CategoryField` receives undefined and operates without breadcrumb/rename support; this is valid.
- **Missing category.onRename**: When `category.onRename` is undefined or omitted, `CategoryField` receives undefined and rename behavior is disabled; this is valid.
- **Disabled state with active user interaction**: When `disabled=true`, both rows are marked disabled but still render; child components determine whether clicks or keyboard input are accepted.
- **className overriding label width**: When a host's `className` also sets `--apt-field-label-w`, the host's value wins: `cn()` places `className` last in the merged class list, and because the same custom property is set on the same element, ordinary CSS cascade order — not import order or specificity — decides the winner, so the later declaration applies without needing `!important`.

