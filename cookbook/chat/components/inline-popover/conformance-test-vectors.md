
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| inline-popover-001 | initialize-with-default-open, set-aria-hidden-attribute | `defaultOpen={true}` | Component renders with `pc-popover-open` class on root and `aria-hidden="false"` |
| inline-popover-002 | initialize-with-default-open, set-aria-hidden-attribute | `defaultOpen={false}` | Component renders without `pc-popover-open` class and `aria-hidden="true"` |
| inline-popover-003 | toggle-visibility-on-click, set-aria-hidden-attribute | User clicks toggle button when open | Component renders with `aria-hidden="true"` and `pc-popover-open` class removed |
| inline-popover-004 | toggle-visibility-on-click, set-aria-hidden-attribute | User clicks toggle button when closed | Component renders with `aria-hidden="false"` and `pc-popover-open` class added |
| inline-popover-005 | render-title-when-provided | `data={{ title: "Test Title" }}` | Title text appears in a `span` with class `pc-popover-title` |
| inline-popover-006 | render-title-when-provided | `data={{ title: "" }}` (`title` is a required `string` on `PopoverData`; an empty string is falsy but still type-valid) | No title element is rendered |
| inline-popover-007 | render-description-when-provided | `data={{ title: "T", description: "Test Description" }}` | Description text appears in a `div` with class `pc-popover-desc` |
| inline-popover-008 | render-description-when-provided | `data={{ title: "T", description: undefined }}` | No description element is rendered |
| inline-popover-009 | render-links-collection | `data={{ title: "T", links: [{ url: "https://example.com", label: "Example" }] }}` | Links container div is rendered with class `pc-popover-links` containing one link element |
| inline-popover-010 | render-links-collection | `data={{ title: "T", links: [] }}` or `data={{ title: "T", links: undefined }}` | No links container is rendered |
| inline-popover-011 | render-each-link-with-label | `data={{ title: "T", links: [{ url: "https://example.com", label: "Click here" }] }}` | Link element displays text "Click here" |
| inline-popover-012 | render-each-link-with-label | `data={{ title: "T", links: [{ url: "https://example.com", label: "" }] }}` (`label` is a required `string` per link; an empty string is falsy but still type-valid) | Link element displays text "https://example.com" as fallback |
| inline-popover-013 | open-links-in-new-tab | `data={{ title: "T", links: [{ url: "https://example.com", label: "" }] }}` | Link element has `target="_blank"` and `rel="noopener noreferrer"` attributes |
| inline-popover-014 | render-arrow-indicator | Any valid data | Arrow span element with class `pc-popover-arrow` is always present in toggle button |
| inline-popover-015 | toggle-visibility-on-click | Toggle button has focus; user presses Enter or Space | Native `button` semantics activate the click handler; open state toggles the same as a mouse click |
| inline-popover-016 | initialize-with-default-open | `defaultOpen` prop omitted | Component initializes open (`pc-popover-open` class present, `aria-hidden="false"`), matching the `defaultOpen = true` default |

