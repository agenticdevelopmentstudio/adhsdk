
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; corrected the invalid-theme-id edge case and design decision 5 to match `getThemeById`'s actual no-throw fallback; removed the unsupported dynamic-theme-switching claim from design decision 4; generalized design decision 1's app reference; reformatted Design Decisions to Decision/Rationale/Approved; rewrote Compliance with a real linked check; rewrote Appearance and Accessibility to describe the static class and the theme's contrast requirement; made the server-safe test vector concrete; rephrased the whitespace-className edge case around the component's own output; relabeled Platform Notes to React/Web and fixed the WinUI 3 equivalent of `data-mdv-theme`; added markdown-renderer to related; unquoted the modified date; added test vectors for null children, invalid theme id, and whitespace className |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source |
