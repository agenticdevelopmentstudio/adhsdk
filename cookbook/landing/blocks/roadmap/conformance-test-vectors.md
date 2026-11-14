
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| roadmap-001 | root-container | No props (only children) | Root div with class `lp-roadmap` rendered |
| roadmap-002 | eyebrow-present | eyebrow="Planned Agents" | Span with class `lp-eyebrow` containing "Planned Agents" rendered inside container |
| roadmap-003 | eyebrow-omitted-when-absent | eyebrow={undefined} or eyebrow prop omitted | No `.lp-eyebrow` element rendered; container div rendered directly with children |
| roadmap-004 | children-content | children={<span>Test content</span>} | Span containing "Test content" rendered inside roadmap container |
| roadmap-005 | eyebrow-present, children-content, eyebrow-precedes-children | eyebrow="Planned", children={<div>List</div>} | Eyebrow span rendered first, then children div, both inside roadmap container |
| roadmap-006 | eyebrow-present | eyebrow={null} | `.lp-eyebrow` span rendered (empty content) because `null` is not `undefined` |
| roadmap-007 | eyebrow-present | eyebrow="" | `.lp-eyebrow` span rendered with empty text content |
| roadmap-008 | eyebrow-present | eyebrow={false} | `.lp-eyebrow` span rendered with no text, because `false` is not `undefined` |
| roadmap-009 | children-content, root-container | children={null} | Root div with class `lp-roadmap` rendered with no child content |
