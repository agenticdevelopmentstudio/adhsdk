
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed must-* requirements to subject-only kebab-case; reformatted Design Decisions into Decision/Rationale/Approved form and added a decision documenting the toolbar-role/keyboard-behavior gap; corrected Compliance check names against the catalog and added keyboard-navigable and no-hardcoded-strings; rewrote Platform Notes to drop the Tailwind/`cn()` coupling outside the React/Web note and to address native toolbar controls per platform; split Conformance Test Vectors into unit class assertions and Playwright pixel/gap vectors, adding a vector for className override precedence; reconciled the Accessibility section with the Empty ariaLabel edge case; populated Localization with the hardcoded default string; added the WAI-ARIA toolbar reference; added tags; fixed modified-date quoting |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
