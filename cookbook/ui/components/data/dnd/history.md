
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only names; split drag-surface config into input and drop-payload requirements with typed shapes; moved dnd-kit implementation values (closestCorners, opacity 0.4, zIndex 20, touch-none) out of requirements into the React/Web platform note; corrected grip dimensions, appearance token roles, and touch-target status; rewrote Platform Notes to the five required bullets with accurate native APIs; converted Design Decisions to Decision/Rationale/Approved format; added Compliance and Localization tables; sharpened ambiguous test vectors and edge-case wording |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Added sortable-surface-config-input and sortable-drop-payload, raised the MAY and SHOULD requirements to MUST, moved dnd-kit and code specifics into the React/Web note, split the dropped announcement key, scoped the no-target edge case to SortableSurface, made vectors dnd-005, dnd-013 and dnd-016 observable, recorded reduced-motion as a Design Decision, and fixed the Compose announcement API. |
