
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-11-14 | Mike Fullerton | Corrected the bar geometry to match css/base.css (1px bars, 4px gap, 5px pitch), moved Appearance MUSTs into named requirements with five computed-style vectors, rewrote Design Decisions 1 and 3, recorded the no-runtime-label-check as Decision 6, dropped the vector that locked in the invalid-icon behavior, recorded the missing focus-visible style in Compliance, and switched to repo-relative paths and fragment links. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Invalid icon renders 2 uncrossed bars, no close class, not a menu-icon fallback (bug logged). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename must-* requirements to subject-only kebab-case and drop the redundant icon-toggle requirement, add a relative-positioning requirement and vector for the hit area, correct the Reduce Motion/Increase Contrast claims against css/base.css, reformat Design Decisions to Decision/Rationale/Approved, replace the Compliance section with a real table, fix vector 009 and add the missing conformance vectors, recommend native platform glyphs first in Platform Notes and rename Web to React/Web, resolve the no-label edge case contradiction, add the consumer-managed aria-expanded/aria-controls guidance, and add button to related |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Resolve review markers: bar dimensions and tap target sourced from css/base.css |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from MenuButton.tsx source |
