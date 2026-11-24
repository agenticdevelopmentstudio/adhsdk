
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | return-focus-on-close and popover-022 corrected: focus-out (Tab past last panel element) does not return focus to the trigger, only Escape/outside-press do; added Edge Case and popover-022 expected result. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: tag requirements, configuration, and platform notes by variant (full-featured vs. lightweight); rename requirements to subject-only kebab-case; correct hide-on-close and focus behavior to match Base UI defaults (non-modal, `keepMounted={false}`); fix SwiftUI/Compose/UIKit/WinUI 3 platform APIs; add `onOpenChange`/`defaultOpen` configuration; reformat Design Decisions to Decision/Rationale/Approved; populate Compliance as a table; add related recipes and Base UI references; move Tailwind class names into the React/Web platform note; split ambiguous test vectors by variant |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Revise Accessibility section: state Base UI delegation as requirements (dialog role, focus trap, Escape handling, aria-expanded); add test vectors for accessibility features; drop review marker |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
