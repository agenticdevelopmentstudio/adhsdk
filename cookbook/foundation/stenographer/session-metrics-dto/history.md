
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionMetricsDTOConformanceTests.swift, 15 of 17 vectors tested, 004 and 005 skipped); unit-test-coverage now partial. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | cutoffISO now round-trips over the wire: its coding key is cutoffIso; vector 005 tested |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Producer and daemon rules rewritten as field-meaning notes, cutoffISO defect restated as a MUST-round-trip marker with vector 005 now expecting the non-nil round trip, parse boundary recorded as a Design Decision, encode and init-default vectors added, edge-case keywords made single-keyword, WinUI 3 note cut to serialization, grouping explained in the Overview, and depends-on and related linked. |
