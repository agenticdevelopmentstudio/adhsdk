
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe, covering the Apple and web avatar-engine config loaders. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.0.2 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.3 | 2026-09-25 | Mike Fullerton | Corrected promote-step-shape (promote field, not family diff), rest-value-derivation (.ink/.family/.shape conditional, no .scale rest), group-member/group-expansion (.scale flattening), predicate-resolution (suppressedIn is moods not a predicate; select is numeric), and pair-fields/idle-fidget field names (idleFidget.durationRange, per-step durationRange). Reworded a Design Decisions rationale sentence that spelled out "NEEDS REVIEW" as prose (word-wrapped across a line break), which was tripping the marker checker; verified the points-count NEEDS REVIEW marker itself already matches the required one-line bullet form and the gap it documents is real (`requireShapeFields` checks field presence only, not count validity), so left it unchanged. |
