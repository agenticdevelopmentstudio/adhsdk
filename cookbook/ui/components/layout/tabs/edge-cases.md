
- **Empty tabs**: If no `TabsTab` children are provided, `TabsList` MUST still render, empty. With no tab present, no panel is selectable.
- **Single tab**: A single tab with no alternative choice may be confusing to users. Component MUST still render and function correctly; design SHOULD consider whether a single tab adds value.
- **No defaultValue**: If both `defaultValue` and `value` are omitted, Base UI selects the tab at index `0` — not the first tab by string `value`. See **default-value**.
- **All tabs disabled**: If every `TabsTab` is disabled, the tab identified by `defaultValue`/`value` MUST remain selected and its panel MUST still display — `disabled` blocks interaction on that tab, it does not clear the Root's selection state. No tab's selection can be changed by click or keyboard while all are disabled, though keyboard focus can still move among the disabled tabs (`focusableWhenDisabled`).
- **Very long tab labels**: Tab text that exceeds container width may wrap or truncate depending on parent width. Component has no word-wrap or text-overflow rule; it MUST render the label as-is. Implementor SHOULD manage parent width constraints or truncate long labels.
- **Rapid tab switching**: Clicking multiple tabs in quick succession MUST result in the most recently clicked non-disabled tab being active; each click is a synchronous state update, and no debouncing is performed.
- **Null or undefined panel content**: If a `TabsPanel` has no children, it MUST render as an empty container without error.

