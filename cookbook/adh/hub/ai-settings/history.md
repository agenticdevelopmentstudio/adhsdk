
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-23 | Mike Fullerton | Phase 8 review fixes: a failed Connect or Refresh request shows its message (refresh-models-failure settled), the editor reads its service from the prop, availability answers patch only their own model, errors are per model, unreadable model entries are dropped |
| 1.0.2 | 2026-11-23 | Mike Fullerton | Track availability changes per model: overlapping changes on different models each keep their own box disabled until their own request settles; vector ai-settings-031. |
| 1.0.1 | 2026-11-23 | Mike Fullerton | Phase 8 verify pass against the code: format.ts moved too, editor syncs liveService from its prop, a box is disabled only while its own request runs, ServicesSectionProps, ModelsTable.test.tsx vectors, Apple model item corrected |
| 1.0.0 | 2026-11-23 | Mike Fullerton | Initial creation: the AI Settings package for phase 8 |
