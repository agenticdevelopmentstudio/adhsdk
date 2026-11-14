
- **Semantic structure**: Tabs MUST be wrapped in `role="tablist"`; links MUST be wrapped in `<nav aria-label="views">` to distinguish navigation type and avoid mixing tabs and links in the same tablist.
- **Tab role and state**: Each tab button MUST have `role="tab"` and `aria-selected` reflecting its active state.
- **Link semantics**: Links MUST be rendered as `<a>` elements with `aria-current="page"` on the active link to indicate current page/location.
- **Icon label fallback**: When a tab's visible label is an icon, the `title` prop MUST be provided to populate both `aria-label` and `title` attributes.
- **Keyboard navigation**: Tabs and links MUST be navigable via Tab key (rendered as interactive elements `<button>` and `<a>`) and active tab/link MUST be indicated by `aria-selected` and `aria-current` respectively. The component relies on native Tab-key focus order between the button/anchor elements; it does not implement the WAI-ARIA tabs pattern's arrow-key/Home-End roving-tabindex navigation or an `aria-controls` link to a tabpanel (see Compliance).
- **Screen reader announcement**: The distinction between tabs (client-state buttons) and links (navigation) is preserved in the DOM structure (separate `role="tablist"` and `<nav>`), enabling screen readers to announce the navigation mode correctly.
- **Minimum touch target**: No explicit touch target size constraint in component; implementors MUST ensure tab and link elements meet platform minimum (44×44pt on iOS per Human Interface Guidelines, 48×48dp on Android per Material Design 3, 44×44px on web per WCAG guidance).

