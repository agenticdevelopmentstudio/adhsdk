
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source code |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Platform Notes: replaced not-applicable bullets with Compose, web and WinUI 3 translation guidance |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added palette/text-color to Configuration with new acceptance requirements; added requirements for alert-tag-to-label replacement and task-list bullet collapse; fixed the checkbox-as-control contradiction in the Compose and WinUI 3 notes and added an Apple reference-implementation note to AppKit/UIKit; resolved the sentinel-collision and soft/hard-break wording contradictions; restructured Design Decisions into Decision/Rationale/Approved form and added a localization-debt decision; evaluated Compliance; split, tightened, and expanded Conformance Test Vectors for testability and coverage; linked markdown-renderer as a dependency |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed mdr-020/Malformed-frontmatter edge case: unclosed leading --- is left unstripped but then parses as a CommonMark thematic break (renders thematicBreakRule), not as literal "---" text. |
