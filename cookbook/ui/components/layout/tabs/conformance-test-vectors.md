
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tabs-001 | render-tab-list | Render `<Tabs><TabsList>...</TabsList></Tabs>` | TabsList renders as flexbox container with bottom border |
| tabs-002 | render-tabs | Render `<TabsTab value="a">Label A</TabsTab>` | Tab renders as clickable button with text |
| tabs-003 | render-panels | Render `<TabsPanel value="a">Content</TabsPanel>` | Panel renders with content visible when tab "a" active |
| tabs-004 | default-value | Render `<Tabs defaultValue="b">` with two tabs | Tab "b" is active on initial render, not tab "a" |
| tabs-005 | active-indicator | Activate a tab by click or prop | Active tab shows gold 2px bottom border, inactive tabs show transparent border |
| tabs-006 | disabled-tabs | Render `<TabsTab value="x" disabled>` and click it | Tab does not change active state, is dimmed to 50% opacity with no hover response, and can still receive keyboard focus (the dimming is a known non-conformance of the current web source) |
| tabs-007 | click-selection | Click a non-disabled tab | Active state changes to that tab; associated panel content displays |
| tabs-008 | aria-tab-roles | Inspect rendered DOM | `role="tablist"` on `TabsList`; `role="tab"` with `aria-selected` on each `TabsTab`; `role="tabpanel"` on each `TabsPanel`; each tab's `aria-controls` equals its panel's id, each panel's `aria-labelledby` equals its tab's id, and a disabled tab has `aria-disabled="true"` |
| tabs-009 | hover-emphasis | Hover over an inactive tab | Text color changes from `apt-text-muted` to `apt-text`; border unchanged |
| tabs-010 | focus-visible-state | Tab to a tab via keyboard | Tab receives focus and shows an indicator distinct from the hover state: `focus-visible:ring-2 focus-visible:ring-apt-gold/40` (plus `focus-visible:text-apt-text` and `focus-visible:rounded-sm`), which hover does not apply |
| tabs-011 | class-name | Pass `className="custom-class"` to Tabs/TabsList/TabsTab/TabsPanel | Custom class appended to element via `cn()` utility (Tailwind class merging) |
| tabs-012 | keyboard-tab-navigation | Focus a tab, press Right arrow | Focus moves to the next tab (including a disabled one); selection does not change, since `TabsList`'s `activateOnFocus` defaults to `false` |
| tabs-013 | keyboard-tab-navigation | Focus any tab, press End | Focus moves to the last tab, whether or not it is disabled |
| tabs-014 | controlled-value | Render with `value` and `onValueChange`, click a different tab | `onValueChange` is called with the new tab's value; the active tab only changes once the parent updates `value` in response |
| tabs-015 | default-value | Render `<Tabs>` with no `defaultValue`/`value` and tabs "a", "b" | The tab at index `0` ("a") is active, regardless of tab `value` strings |
| tabs-016 | keyboard-tab-navigation | Focus any tab, press Home | Focus moves to the first tab |
| tabs-017 | keyboard-tab-navigation | Focus is outside the tablist; press Tab, then Tab again | The first Tab lands on the active tab (one stop for the whole list); the second leaves the tablist |
| tabs-018 | keyboard-tab-navigation | Direction rtl (supplied through Base UI's `DirectionProvider`; the `dir` attribute alone is not read); focus a tab and press Left | Focus moves to the next tab; Right moves to the previous |
| tabs-019 | visible-label | Render `<TabsTab value="a">Label A</TabsTab>` | The tab's accessible name is its visible text "Label A" |
| tabs-020 | disabled-tabs | Every `TabsTab` is `disabled`, `defaultValue="b"` | Tab "b" stays selected and its panel displays; clicking another tab changes nothing |
| tabs-021 | render-tab-list | Render `<TabsList />` with no tabs | The list renders, empty; no panel is selected |
| tabs-022 | render-panels | Render `<TabsPanel value="a" />` with no children while tab "a" is active | The panel renders as an empty container without error |
| tabs-023 | click-selection | Click tab "b", then tab "c", then tab "a" in quick succession | Tab "a" is active and its panel displays |
