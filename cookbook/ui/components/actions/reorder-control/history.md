
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | Fixed busy-state-appearance: aria-disabled belongs to both buttons only; group gets aria-busy, not aria-disabled. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Renamed `may-accept-custom-className` to the subject-only `custom-class-name`. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; added requirements and test vectors for the busy/boundary overlap, aria-busy, empty-subject, both-boundaries-disabled, and busy-to-idle edge cases; corrected Appearance and minimum-tap-target values against the source; reworded the ghost/icon-sm and lucide-react-specific requirements and test vector as platform-neutral intent, moving the web specifics to Platform Notes; fixed the SwiftUI and WinUI 3 busy-state focus guidance; filled in the Compliance table; split Design Decisions into Decision/Rationale/Approved blocks; added the InlineCommitControl related-domain and an aria-disabled reference. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
