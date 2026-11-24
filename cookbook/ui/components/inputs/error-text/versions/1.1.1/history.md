
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web implementation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: folded duplicate requirements (alert role, dialog treatment) into their survivors; renamed all requirements to subject-only kebab-case; split the color/size requirement so it matches the documented `className` override policy, grounded in `cn()`'s `tailwind-merge` behavior; moved Tailwind class names out of Behavioral Requirements and into the React/Web platform note; corrected the SwiftUI, UIKit/AppKit, Compose, and WinUI 3 accessibility-announcement APIs; hedged two edge cases that stated uncertain screen-reader/DOM behavior as fact; reformatted Design Decisions into named Decision/Rationale/Approved entries; added a Compliance table; added test vectors for `className` merging on `DialogErrorText`, the size-override behavior, and the hidden-container DOM-presence case |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
