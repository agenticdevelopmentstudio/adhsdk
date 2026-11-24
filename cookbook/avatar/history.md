
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation from the `@adh-sdk/avatar` web source (engine, arbitration, gaze, idleLife, pose, reflexes, speechBubble, types); flagged three genuine gaps — unvalidated MorphSVG point-count matching, unvalidated Pose/Tuning shape at runtime, and no reduced-motion accommodation for the engine's continuous idle loops — with the open question and evidence needed for each recorded in place. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Antennae per-pose rotation/offset tween now runs regardless of eyesShut; neutral bend applies on top, not instead. |
| 1.0.3 | 2026-11-14 | Mike Fullerton | Lint fixes: forced-gaze clamp added to gaze-forced-priority with a new vector, Tuning field names and sleepMutterMs used consistently, blink and tuning vectors made precise, validation gaps restated with RFC keywords, two debt Decisions added, and unverified WinUI 3 guidance flagged. |
