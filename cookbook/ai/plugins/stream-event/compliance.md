
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |

Notes: separation-of-concerns passes because the event enum (`AIStreamEvent`) is kept separate from the decoding protocol (`AIStreamDecoder`), and decoding itself is kept separate from the host's transport and framing — `PluginTransport` supplies the bytes, this file only turns bytes already in hand into typed events. unit-test-coverage passes because `PluginDecoderTests.swift`, `PluginTransportTests.swift`, and `PluginTransportFramingTests.swift` exercise every shipped decoder and the framing contract directly. explicit-error-handling fails because a malformed or unparseable frame is silently swallowed as `[]` from `consume(_:)`/`finish()` with no distinct signal reaching the host, per decode-failure-signal and its Design Decision. fault-tolerance is partial because `consume(_:)` and `finish()` never throw or crash on unexpected byte input — every shipped decoder falls back to returning no event — but a permanently malformed frame stays indistinguishable from one that is merely incomplete, the same gap covered by decode-failure-signal.

