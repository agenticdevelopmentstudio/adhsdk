
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the InfoPanel + StatRow + ExternalLink assembly extracted from the status telemetry cards. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | `actions` header slot (extra controls after the deep link) + host-attribute passthrough to the panel root; adopted by the fleet status monitor card. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Correct domain URIs to agenticdevelopercookbook:// and complete Platform Notes with all five platform bullets and explanations. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Rewrite WinUI 3 platform note with concrete translation guidance: Border, Grid header, StackPanel body, TextBlock pairs for stats, Visibility bindings for optional elements. |
| 1.4.0 | 2026-09-22 | Mike Fullerton | Lint pass: strip `must-` from every requirement name and its citations; add title-as-accessible-name requirement; straighten summary quotes; add related domains for the recipe-as-ingredient pattern; rewrite Compliance as linked catalog checks with passed/partial statuses; add Approved: pending to each Design Decision; add three Integration Test Vectors (actions-slot omission, children-before-footnote order, actions-without-link); rewrite WinUI 3 header/actions/host-attribute guidance and give SwiftUI, Compose, and AppKit/UIKit concrete translation guidance in place of Not applicable; clarify the footnote is always last in the body stack. |
| 1.4.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
