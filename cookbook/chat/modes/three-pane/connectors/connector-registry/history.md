
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, added stable-snapshot-identity and replace-on-conflict requirements with test vectors, corrected the snapshot-immutability and subscribe-on-add claims, made requirements platform-neutral and moved hook names into Platform Notes, corrected the SwiftUI/Compose/AppKit/WinUI notes to match per-subtree scoping, reformatted Design Decisions, dropped the inapplicable Compliance section, tightened test-vector precision and added edge-case vectors, and expanded the Overview |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Restored a genuine Compliance section (separation-of-concerns/explicit-error-handling passed, unit-test-coverage failed: only one shallow test exists). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Made stale-unregister-noop, unsubscribe-during-notify and snapshot-liveness named requirements, made unregister idempotent, added vector 015, moved web details into Platform Notes, explained how SwiftUI and Compose meet the sync requirements, reworded the summary and linked connector-svg as related. |
