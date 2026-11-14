
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe — extracted from the hub research filter bar into `@adh-shared/ui`. |
| 1.1.0 | 2026-08-24 | Mike Fullerton | Added `asForm` for the iOS autofill scoping the registry search needs. Brought the spec back level with the component: `{ value, label }` options, `orientation`, `children`, `aria-label`, `onKeyDown`, and the moved source path. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Added missing sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy) with appropriate non-applicable explanations. Moved status to review. |
| 1.2.1 | 2026-09-22 | Mike Fullerton | Expanded Platform Notes with concrete translation guidance for SwiftUI, Compose, AppKit / UIKit, and WinUI 3; removed "Not applicable" from all non-source platforms. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected `depends-on` to the Input/Select recipes; added `Approved: pending` to every Design Decision; rebuilt Compliance as linked, catalog-derived checks; fixed wrong native APIs and the orientation mapping in the SwiftUI, AppKit/UIKit, and WinUI 3 platform notes and removed their fabricated `asForm`/debounce claims; corrected the stale-selected-value and duplicate-option-strings edge cases with a new conformance vector; fixed the Filter-active state description; and collapsed the duplicated Analytics/Logging text. |
| 1.3.1 | 2026-09-24 | Mike Fullerton | Renamed `may-scope-autofill-with-a-form` to the subject-only `autofill-form-scope`. |
| 1.3.2 | 2026-09-25 | Mike Fullerton | Reshaped Design Decisions into `**Decision**`/`**Rationale**`/`**Approved**` line triples. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
