
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`input-sanitization` **passed**: `escapedForScriptElement(_:)` escapes every
character an extension-authored `initialState` could use to break out of
the `<script>` element it is embedded in, and both break-out families —
closing the script tag early, opening an HTML comment — are covered by a
named test each (webview-host-document-009, webview-host-document-010).
`separation-of-concerns` **passed**: this file only assembles the document
and generates the bootstrap script; decoding the messages that bootstrap
sends back is a separate component's job (`WebviewMessageRelay` in
`WebviewPanelViewController.swift`), not this one's.
`unit-test-coverage` **passed**: `WebviewHostDocumentTests.swift` exercises
head insertion, the no-head fallback across three markup shapes, case
insensitivity, markup passthrough, both state-embedding paths, both
break-out families, and the two shared bridge names. `explicit-error-handling`
is **partial**: `html(wrapping:initialState:)` has no error path of its own
to swallow, but the one place an error can occur — a non-nil `initialState`
that is not valid JSON — throws inside a JavaScript IIFE with no signal
reaching this file's caller (**initial-state-json-validity**).
`idempotent-operations` **passed**: `html(wrapping:initialState:)` is a
pure function of its two arguments; repeated calls with identical arguments
return identical strings. `no-hardcoded-strings` **failed**: the
acquire-once error message is hardcoded English with no lookup table or
locale parameter anywhere in this file (see Localization) — a plain,
honestly-reported gap in the source, not a hidden one.

