
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and split them into platform-neutral behaviors (render-children, no-own-scroll, merges-style-hook, focusable-not-tabbable, not-a-landmark) with web specifics moved to React/Web notes; rewrote the tabIndex rationale as the concrete click-then-scroll sequence and added matching test vectors deck-007 through deck-011 plus edge-case cross-references; reformatted Design Decisions to Decision/Rationale/Approved; linked real accessibility compliance checks; corrected the Compose, WinUI 3, SwiftUI, and AppKit/UIKit platform notes; added tags and related ingredients. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Added the document-gate requirement and deck-012, rewrote Appearance to describe the document-level effects, reworded Compliance for four rows, moved the div/lp-deck detail to the React/Web note, corrected deck-011, added SwiftUI focus and landmark guidance and a neutral merges-style-hook wording. |
