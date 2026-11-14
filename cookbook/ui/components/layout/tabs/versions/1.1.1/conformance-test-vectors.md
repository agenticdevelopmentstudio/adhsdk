
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tabs-001 | render-tab-list | Render `<Tabs><TabsList>...</TabsList></Tabs>` | TabsList renders as flexbox container with bottom border |
| tabs-002 | render-tabs | Render `<TabsTab value="a">Label A</TabsTab>` | Tab renders as clickable button with text |
| tabs-003 | render-panels | Render `<TabsPanel value="a">Content</TabsPanel>` | Panel renders with content visible when tab "a" active |
| tabs-004 | default-value | Render `<Tabs defaultValue="b">` with two tabs | Tab "b" is active on initial render, not tab "a" |
| tabs-005 | active-indicator | Activate a tab by click or prop | Active tab shows gold 2px bottom border, inactive tabs show transparent border |
| tabs-006 | disabled-tabs | Render `<TabsTab value="x" disabled>` and click it | Tab does not change active state; the tab still shows full opacity, still responds to hover, and can still receive keyboard focus — only the click-activation is blocked |
| tabs-007 | click-selection | Click a non-disabled tab | Active state changes to that tab; associated panel content displays |
| tabs-008 | aria-tab-roles | Inspect rendered DOM | `role="tablist"` on `TabsList`; `role="tab"` with `aria-selected` on each `TabsTab`; `role="tabpanel"` on each `TabsPanel` |
| tabs-009 | hover-emphasis | Hover over an inactive tab | Text color changes from `apt-text-muted` to `apt-text`; border unchanged |
| tabs-010 | focus-visible-state | Tab to a tab via keyboard | Tab receives focus; text color changes via `focus-visible` (no ring, `outline-none`); visually identical to the hover state |
| tabs-011 | class-name | Pass `className="custom-class"` to Tabs/TabsList/TabsTab/TabsPanel | Custom class appended to element via `cn()` utility (Tailwind class merging) |
| tabs-012 | keyboard-tab-navigation | Focus a tab, press Right arrow | Focus moves to the next tab (including a disabled one); selection does not change, since `TabsList`'s `activateOnFocus` defaults to `false` |
| tabs-013 | keyboard-tab-navigation | Focus any tab, press End | Focus moves to the last tab, whether or not it is disabled |
| tabs-014 | controlled-value | Render with `value` and `onValueChange`, click a different tab | `onValueChange` is called with the new tab's value; the active tab only changes once the parent updates `value` in response |
| tabs-015 | default-value | Render `<Tabs>` with no `defaultValue`/`value` and tabs "a", "b" | The tab at index `0` ("a") is active, regardless of tab `value` strings |

