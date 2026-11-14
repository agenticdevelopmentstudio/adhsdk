
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: replace nonexistent Platform Notes APIs with real mechanisms; rename requirements to subject-only kebab-case and merge the duplicate classname requirements/vectors; add a kb-inset-read-only requirement plus ViewportShell/useKeyboardInset dependencies; split the untestable keyboard vector into a unit test and a Playwright test; correct the base-stylesheet and safe-area-prerequisite edge cases; reformat Design Decisions into Decision/Rationale/Approved blocks; and replace "Not applicable" Compliance with a real table |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Dropped the dangling URI of the never-written use-keyboard-inset recipe from depends-on, related, and kb-inset-read-only; pointed to viewport-shell's keyboard-inset requirement instead. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
