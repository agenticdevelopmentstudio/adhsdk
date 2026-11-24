
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionEventEncodingConformanceTests.swift, SessionEventSinkConformanceTests.swift, IngestionPipelineTests.swift extended, 13 of 14 vectors); unit-test-coverage now partial (013 skipped: IngestedEvent cannot fail to encode). |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added a slash-escaping requirement and a caller obligation for encode failure, restated the encoder statelessness requirement, added RFC 2119 wording to sink-no-delivery-signal, cited EventIngestor, drove the sink vectors through EventIngestor, trimmed Configuration, filled depends-on and related, and emptied references. |
