
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the header anatomy, content-sized vs fill+scroll body, and the shared header-height alignment. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | Host-attribute passthrough: remaining HTML attributes spread onto the root `<section>` (data-* tagging without a wrapper). |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Complete recipe sections: add Deep Linking, Localization, Accessibility Options, Feature Flags, Privacy; expand Platform Notes with translation guidance for all five platforms; set status to review. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere they're cited; resolve the label-region contradiction with Edge Cases and state the aria-label precedence, with new test vectors T15-T18; correct the keyboard-scrollable overclaim; write a Logging statement distinct from Analytics; reformat Design Decisions and Compliance to the canonical forms; fix WinUI 3's Grid/MinHeight, the SwiftUI/AppKit min-height wording, AppKit-vs-UIKit padding APIs, and Compose's scroll-gated fillMaxHeight; mark T6/T8 as Playwright/E2E and reword T5 behaviorally; rewrite Appearance in neutral terms and move Tailwind classes into the React/Web note; drop the unsupported "manages layout state" phrase from Privacy. |
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
