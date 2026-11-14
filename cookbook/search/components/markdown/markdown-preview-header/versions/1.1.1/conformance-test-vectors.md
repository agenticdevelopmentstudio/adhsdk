
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| header-001 | title-fallback | hit.title = "Example Paper" | h3 displays "Example Paper" |
| header-002 | title-fallback, title-attribute | hit.title = "" | h3 text displays "Untitled"; h3 title attribute = "" |
| header-003 | title-fallback, title-attribute | hit.title = null | h3 text displays "Untitled"; h3 title attribute = "" |
| header-004 | title-fallback | hit.title = undefined | h3 text displays "Untitled" |
| header-005 | title-fallback | hit.title = "   " (whitespace only) | h3 text displays "   " literally — not "Untitled", since the fallback is a falsy check, not a trim |
| header-006 | title-attribute | hit.title = "Long Paper Title Here" | h3 title attribute = "Long Paper Title Here" |
| header-007 | kind-badge | hit.kind = "research", kindRendererFor returns {badge: {variant: "research", label: "Research"}} | Badge renders with variant "research" and label text "Research" |
| header-008 | author-attribution | hit.author = {displayName: "Alice Smith", slug: "alice"} | Text shows "by Alice Smith" |
| header-009 | author-attribution | hit.author = {displayName: "  ", slug: "bob"} | Text shows "by @bob" |
| header-010 | author-attribution | hit.author = {displayName: null, slug: "charlie"} | Text shows "by @charlie" |
| header-011 | author-attribution | hit.author = {displayName: undefined, slug: "dave"} | Text shows "by @dave" |
| header-012 | optional-date | hit.updatedAt = "2026-09-20", viewer time zone UTC (or any zone at or east of UTC) | Text displays "Updated Sep 20, 2026" (formatDate's en-US short-month format); under a time zone west of UTC (e.g. `America/Los_Angeles`) the same input instead displays "Updated Sep 19, 2026", because `formatDate` parses the date-only string as UTC midnight and formats with no `timeZone` option |
| header-013 | optional-date | hit.updatedAt = null | Date text does not render |
| header-014 | optional-date | hit.updatedAt = undefined | Date text does not render |
| header-015 | optional-date | hit.updatedAt = "" | Date text does not render |
| header-016 | optional-summary | hit.summary = "This is a summary" | Summary paragraph visible |
| header-017 | optional-summary, summary-label | hit.summary = "This is a summary" | Paragraph text reads "Summary: This is a summary" |
| header-018 | optional-summary | hit.summary = "" | Summary paragraph does not render |
| header-019 | optional-summary | hit.summary = "   " | Summary paragraph does not render |
| header-020 | optional-summary | hit.summary = null | Summary paragraph does not render |
| header-021 | per-kind-extra | renderer.previewExtra(hit) returns a React element | Extra section renders that element |
| header-022 | per-kind-extra | renderer.previewExtra(hit) returns null | Extra section does not render |
| header-023 | per-kind-extra | renderer.previewExtra(hit) returns undefined | Extra section does not render |
| header-024 | public-link | hit.publicRoute = "/papers/example" (non-empty string), href = "https://example.com/paper" | Link visible with text "View full paper" and href="https://example.com/paper" |
| header-025 | public-link | hit.publicRoute = "" | Link does not render |
| header-026 | public-link | hit.publicRoute = "", href = "https://example.com/paper" (well-formed) | Link does not render, regardless of href's value |
| header-027 | metadata-row-order | hit with kind badge, author, and updatedAt all present | Badge, author text, and date text appear in that order within one wrapping row |

