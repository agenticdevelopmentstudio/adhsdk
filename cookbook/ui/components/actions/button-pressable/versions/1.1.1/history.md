
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: restated requirements over the observable `data-pressed`/active-press contract instead of the internal `held` state, renamed all requirements to subject-only kebab-case, replaced the ad hoc Compliance table with real accessibility checks, reformatted Design Decisions to the three-line form, cited `button-pressable.tsx` directly instead of "the source comment", softened unreferenced cross-platform API claims to "typically", dropped the untestable handler-ordering requirement in favor of a Design Decision, fixed the invalid `setPointerCapture` test vector, added a States row and two edge cases for multi-pointer overlap and post-release re-entry, declared this recipe the single owner of the press-tracking contract, and linked the Accessibility Options reference |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: failed). |
