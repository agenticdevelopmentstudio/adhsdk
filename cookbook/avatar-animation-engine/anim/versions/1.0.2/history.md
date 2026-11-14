
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe covering `Arbiter.swift`/`arbiter.ts`, `Params.swift`/`params.ts`, `Poses.swift`/`pose.ts`, `Reflexes.swift`/`reflexes.ts`, and `Timelines.swift`/`timeline.ts`, with the open question about unvalidated non-finite gaze input carried as the one open item for a future revision to resolve. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | unknown-timeline-rejected now cancels the running timeline before throwing; stir-branch-selection uses a seeded Bernoulli draw on branch.probability, not a predicate; vector 8 corrected to reflect the idle ladder taking over after the waking window, not waking.to. Converted the Conformance Test Vectors section from a numbered list into a pipe table, mapping each of the 10 existing vectors to its Behavioral Requirement name(s), and added `macos`/`ios` to the frontmatter `platforms` list. |
