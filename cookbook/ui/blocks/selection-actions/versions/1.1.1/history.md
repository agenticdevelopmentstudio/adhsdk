
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added requirements for the confirm modal's destructive styling, confirm/cancel button labels, closing on confirm, and the onDelete selection argument; replaced the impossible "modal already visible" edge case with a duplicate-action-id edge case and vector; populated depends-on, related, and references; moved web-only Appearance details into the React/Web platform note; corrected the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes to real APIs; rewrote Localization to list the component's unoverridable hardcoded strings instead of "Not applicable"; dropped the "stateless" claim from Feature Flags; reformatted Design Decisions into Decision/Rationale/Approved form; and rebuilt Compliance as a linked table reflecting that touch-target-size and no-hardcoded-strings fail. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added missing duplicate-action-ids requirement; K20c dangling ref now resolves. |
