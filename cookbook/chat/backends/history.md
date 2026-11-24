
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe covering `types.ts`, `EventQueue.ts`, `FetchBackend.ts`, `MockBackend.ts`, `ShuffleBag.ts`, `ChatBackendAdapter.ts`, and `PersonaChatBackend.ts`; documents the cross-implementation divergences between `ChatBackendAdapter` and `PersonaChatBackend` and the open question around concurrent direct use of a bare `ChatBackend`.
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Fixed ccb-044 pipe escape, history/transport-failure/SSE edge cases; kebab-cased 4 req names. |
| 1.0.3 | 2026-11-14 | Mike Fullerton | Lint fixes: attributed the attachment, widget and destroyed errors to ChatBackendAdapter, corrected the ShuffleBag callers in the overview and a decision, gave event-queue-single-consumer an RFC keyword, merged the duplicate concurrency edge case into its marker, and made vectors ccb-007 and ccb-012 discriminating. |
