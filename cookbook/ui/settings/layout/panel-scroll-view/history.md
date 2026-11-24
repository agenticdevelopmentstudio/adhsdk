
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.1 | 2026-11-23 | Mike Fullerton | Repoint the Platform Design Languages guideline link to its surviving adc artifact after adc folded the duplicate copy. |
| 1.3.0 | 2026-11-18 | Mike Fullerton | Content width is a value fed from the viewport at layout, preferred at just below the default-high strength, never a constraint to the viewport: a required equal-width constraint let a wide row (a popup beside two buttons) widen the viewport and move the split's divider. Wider content now scrolls sideways. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added Compliance rows for separation-of-concerns and unit-test-coverage |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/layout/. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: downgrade content-replacement-resets-scroll-position and horizontal-scroller-enabled from MUST to SHOULD/MAY with corrected rationale; move the internal `agenticdevelopercookbook://` link from `references` to `related`; strip RFC 2119 keywords from non-requirement Edge Cases prose; fix "recipe"/"ingredient" wording in the WinUI 3 note; correct programmatic-instantiation-only and its test vector to describe compile-time rejection instead of a runtime trap; add an integration test vector for split-view divider stability; fix the WinUI 3 MinHeight binding to `SizeChanged` only; reformat Design Decisions to the canonical three-line form; replace invented Compliance citations with a real catalog check |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
