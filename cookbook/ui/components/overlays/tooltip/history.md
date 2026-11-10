
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Narrowed frontmatter platforms to typescript/web, matching the component's single web source. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; restate must-use-portal/must-support-custom-className as outcomes and move their React specifics into the React/Web platform note; rewrite non-web Platform Notes around each platform's native tooltip API and correct unsupported/inaccurate claims (SwiftUI, Compose, WinUI 3, 200ms default); add dismiss/hover-persist requirements and test vectors plus an RTL test vector; rewrite edge cases as RFC 2119 requirements with vectors; resolve the z-index and arrow-size contradictions; reformat Design Decisions to the three-line form; normalize the Compliance table and fix frontmatter platforms/related drift |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Remove review marker from Accessibility section; state that wrapper inherits Base UI Tooltip's role and aria-describedby wiring for screen reader announcement |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from Base UI tooltip source |
