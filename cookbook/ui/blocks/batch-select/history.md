
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and split the conflicting set-reference requirement into set-selected-ids-new-reference and reset-uses-shared-empty-selection; reformatted Design Decisions into the three-line form; documented Configuration options; rewrote Localization to use real string keys; fixed test vectors 006 and 010 and added vectors for provide-set-selected-ids, the rapid-toggle and non-primitive-resetKey edge cases, and shared-empty-Set identity; renamed the resetKey edge case; corrected Platform Notes to use real native toggle APIs (SwiftUI `Toggle`/`.toggleStyle(.button)`, Compose `Modifier.toggleable`, UIKit `changesSelectionAsPrimaryAction` plus the `.selected` trait, WinUI `ToggleButton`/`IsChecked` and `IReadOnlySet<string>`); corrected the Compliance table to reference real catalog checks |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: removed source line-number citations. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
