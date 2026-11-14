
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: merged duplicate requirements into drawer-toggle-controls, close-on-link-click, and trap-tab-inside-drawer; rewrote implementation-coupled requirements as observable, platform-neutral behavior; renamed all requirements to subject-only kebab-case; fixed the toggle/close ambiguity and three contradictions (fragment default-navigation, scroll-behavior ownership, Shift+Tab exit claim); reformatted Design Decisions to Decision/Rationale/Approved and corrected two decisions' rationale; added a Compliance table; corrected Platform Notes APIs and pointed each port at its native drawer control; fixed dangling and mis-scoped test-vector references and added two missing vectors; retitled the recipe; documented the drawer's intentional departure from the full ARIA dialog-modal pattern |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Burger only opens the drawer (never closes); nav-005 corrected to no-op. |
