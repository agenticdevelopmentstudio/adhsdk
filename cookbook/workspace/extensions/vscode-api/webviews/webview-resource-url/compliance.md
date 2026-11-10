
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because naming a URL (`hostDocumentURL`,
`url(forFile:)`), deciding what a URL names (`target(of:)`), and deciding
whether a path is contained (delegated entirely to `ExtensionResourcePath`)
are three distinct responsibilities that this file keeps apart rather than
folding into one function (`resource-url-naming-only`, `containment-
delegation`). `input-sanitization` passes because every URL this file
decides on is, per its own header comment, from a hostile webview page, and
`target(of:)` never trusts it: scheme, panel identity, and file containment
are each checked in order before a `.file` result is ever returned
(`scheme-validation-first`, `panel-validation-second`, `candidate-
canonicalization`). `explicit-error-handling` passes because the three
failures this file defines are never swallowed — they are typed, `Equatable`,
`LocalizedError`-conforming cases a caller must catch, and the one production
caller this recipe traced (`WebviewSchemeHandler`) does catch and act on
every one of them (`error-case`, `error-message`). `unit-test-coverage`
passes: `WebviewResourceURLTests.swift` exercises the naming round trip
(including percent-encoding), the host document, every refusal path
(no roots, outside every root, a name-prefix sibling, the root itself, a
traversal, a wrong panel, a wrong scheme), and the scheme constant's shape
directly. `no-hardcoded-strings` fails: `errorDescription` returns one of
three fixed English sentences with no localization lookup of any kind, so
the message an extension author or developer sees when a resource is
refused is English regardless of the host's locale (`error-message`,
Localization).

