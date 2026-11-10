
- **compose-two-fields**: Component MUST render `CategoryField` with `layout="inline"` and `TagSetField` with `layout="inline"` vertically stacked, `CategoryField` first.
- **share-label-width**: Component MUST set the `--apt-field-label-w` CSS custom property on its root element to ensure both rows' label columns have equal width and right edges align.
- **accept-category-data**: Component MUST accept a `category` object containing `label`, `noun`, `options`, `value`, and `onChange`; it MUST pass these to `CategoryField`.
- **accept-category-nodes**: Component MUST accept an optional `category.nodes` array and pass it to `CategoryField` for breadcrumb and rename behavior.
- **accept-category-rename**: Component MUST accept an optional `category.onRename` callback and pass it to `CategoryField`.
- **accept-tags-data**: Component MUST accept a `tags` object containing `label`, `noun`, `options`, `value` (array), and `onChange`; it MUST pass these to `TagSetField`.
- **disable-both-rows**: Component MUST pass the `disabled` prop (default `false`) to both `CategoryField` and `TagSetField`.
- **forward-classname**: Component MUST accept an optional `className` and merge it onto its root element so host styling composes with the component's own classes rather than replacing them.
- **use-gap-between-rows**: Component MUST apply 12px of vertical spacing between the two rows.
- **render-data-slot**: Component MUST set `data-slot="categories-and-tags"` on its root element.
- **require-category-label-noun**: `category.label` and `category.noun` are required (non-optional) string properties in the component's props type; the component MUST NOT supply a default value for either, and omitting either one MUST be a compile-time type error rather than a silent render with `undefined`.
- **require-tags-label-noun**: `tags.label` and `tags.noun` are required (non-optional) string properties in the component's props type; the component MUST NOT supply a default value for either, and omitting either one MUST be a compile-time type error rather than a silent render with `undefined`.
- **preserve-tab-order**: Component MUST render `CategoryField` before `TagSetField` in DOM order, so keyboard focus visits the category row before the tags row.

