
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mrr-001 | render-title | `hit.title = "My Document"` | Renders h3 with text "My Document" |
| mrr-002 | render-title | `hit.title = null` or empty string | Renders h3 with text "Untitled" |
| mrr-003 | highlight-title | `hit.title = "Search results", query = "search"` | Title renders with "Search" wrapped in `<mark>` element |
| mrr-004 | highlight-title | `hit.title = "No match", query = "xyz"` | Title renders with no `<mark>` elements |
| mrr-005 | render-per-kind-badge | `hit.kind = "paper"` with registered renderer | Badge renders with variant and label from renderer.badge |
| mrr-006 | render-per-kind-badge | `hit.kind = "unknown"` or unregistered | Component does not throw; renders with default renderer badge |
| mrr-007 | render-snippet | `renderer.rowSnippet(hit) = "  Some text  "` | Snippet renders as "Some text" (trimmed) |
| mrr-008 | render-snippet | `renderer.rowSnippet(hit) = ""` (empty after trim) | Snippet section is not rendered |
| mrr-009 | highlight-snippet | `snippet = "Find results fast", query = "results"` | Snippet renders with "results" wrapped in `<mark>` |
| mrr-010 | limit-snippet-lines | Snippet contains 4+ lines of text | CSS clamp limits visible lines to 2; overflow indicated by ellipsis |
| mrr-011 | render-tags | `hit.tags = ["tag1", "tag2"]` | Renders two separate elements, "#tag1" and "#tag2" (no comma separator) |
| mrr-012 | render-tags | `hit.tags = []` | Tags section is not rendered |
| mrr-013 | render-category | `hit.category = "Research"` | Renders uppercase label "RESEARCH" in styled capsule |
| mrr-014 | render-category | `hit.category = null` or empty string | Category section is not rendered |
| mrr-015 | render-author-display | `hit.author.displayName = "Jane Doe"` | Renders "by Jane Doe" |
| mrr-016 | render-author-display | `hit.author.displayName = ""` or null, `hit.author.slug = "jdoe"` | Renders "by @jdoe" |
| mrr-017 | render-updated-date | `hit.updatedAt = ISO 8601 date string` | Renders " · Updated {formatDate(hit.updatedAt)}" (e.g. " · Updated Jun 24, 2026") after the author line |
| mrr-018 | render-updated-date | `hit.updatedAt = null` or undefined | Date portion of footer is not rendered |
| mrr-019 | bind-select-callback | User clicks the button | `onSelect(hit)` is called with the hit object |
| mrr-020 | highlight-selected-state | `selected = true` | Border color is accent (`apt-gold`) |
| mrr-021 | highlight-selected-state | `selected = false` | Border color is neutral; hover state applies strong border |
| mrr-022 | indicate-pressed-state | `selected = true` | `aria-pressed="true"` on button element |
| mrr-023 | indicate-pressed-state | `selected = false` | `aria-pressed="false"` on button element |
| mrr-024 | implement-roving-tabindex | `active = true` | Button and link have `tabIndex={0}` |
| mrr-025 | implement-roving-tabindex | `active = false` | Button and link have `tabIndex={-1}` |
| mrr-026 | implement-roving-tabindex | `active = undefined` | No tabindex attribute set; natural tab order applies |
| mrr-027 | forward-ref-to-button | `controlRef` is a React ref object | `controlRef.current` points to the button DOM element |
| mrr-028 | manage-link-tabindex | `active = true` (button's tabIndex is 0) | Link element also has `tabIndex={0}` |
| mrr-029 | enlarge-link-touch-target | "View paper" link is rendered | Invisible `::after` overlay covers full link width with 24px height |
| mrr-030 | enlarge-link-touch-target | User touches link near but outside text bounds | Touch target is activated if within the 24px overlay zone |
| mrr-031 | set-link-href | `href = "/paper/123"` | Link element has `href="/paper/123"` |
| mrr-032 | escape-content | `hit.title` contains `<script>alert('xss')</script>` | Content is rendered as text, script is not executed |
| mrr-033 | render-rounded-corners | Component is rendered | Article, badge, and focus rings display consistent rounded corners |

