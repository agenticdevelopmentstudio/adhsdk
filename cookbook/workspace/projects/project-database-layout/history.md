
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial recipe, documenting `ProjectDatabase+Layout.swift` as of its current form — tab/tree/pane-state/project-directories persistence, the two open gaps around malformed-row signaling and read-side active-tab consistency, and the schema-migration crash-recovery behavior it inherits from the base `ProjectDatabase`. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: removed source line-number citations; recipes cite files and symbols, not lines. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to workspace/projects/. |
| 1.2.0 | 2026-10-04 | Mike Fullerton | Resolved the corrupt-row NEEDS REVIEW marker against source (silent drop, no logging) as a pending decision; converted test vectors to a table and Design Decisions to Decision/Rationale/Approved triples. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Requirements use the named-bullet form, `- **id**: ...`, instead of an em dash after the id. |
| 1.3.0 | 2026-11-15 | Mike Fullerton | Tab edges are an explicit per-project Tab Bars choice: no stored edges means follow the app-wide tab positions live, an empty enabled_edges value means no choice, and the shared tab configuration carries only the pane arrangement. |
