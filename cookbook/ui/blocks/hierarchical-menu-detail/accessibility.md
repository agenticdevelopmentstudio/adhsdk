
- **Role**: The root is a flex container wrapping a `nav` (breadcrumb) and multiple aside-like sections (rail columns). The `nav` element carries `aria-label="Breadcrumb"`.
- **Breadcrumb navigation**: Semantic nav + ol/li structure. Current crumb marked with `aria-current="page"`. Crumb buttons use `aria-label` or visible text; chevron separators marked `aria-hidden`.
- **Column identification**: Each list column carries an internal index marker used to locate the selected row's endpoint for connector paths; selection within each column is marked with `aria-current="true"` on the selected row element. Rail-internal roles, accessible names, and row-level keyboard navigation (arrow keys) are the TopicRail ingredient's concern — see [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f).
- **Header toggles**: AutoHide toggle has `aria-label`, `aria-pressed` showing toggle state; its labels are the `htd.autoHide.on` and `htd.autoHide.off` strings (see Localization). Pin toggles carry `aria-label` from `htd.cover.cover` and `htd.cover.uncover`, and the cascading immersion toggle from `htd.immerse.hide` and `htd.immerse.show`.
- **Offscreen columns**: Hidden columns marked `aria-hidden="true"` and `pointer-events-none`.
- **Back button (narrow mode)**: Labeled `aria-label="Back"`, showing a chevron-left icon + text.
- **Decorative elements**: Icons used as decoration (chevron-right in breadcrumb, icon-only toggles) marked `aria-hidden`.
- **Selection connectors**: SVG path overlay marked `aria-hidden` and `pointer-events-none`.
- **Minimum touch target**: Header toggles measure roughly 2.15rem (~34px) tall with small icon padding; breadcrumb crumbs are text-sized click targets. Neither meets the 44×44px touch-target guideline (see Compliance).
- **Keyboard navigation**: Breadcrumb crumbs, header toggles, and the Back button are native `<button>` elements, focusable and activatable via standard keyboard controls (Tab, Enter/Space). Row-level keyboard navigation is the TopicRail ingredient's concern — see [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f).
- **Label clarity**: Breadcrumb uses visible text; toggles use `aria-label` + visible icon. Lists inherit labels from TopicRail.

