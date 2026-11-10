
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the file cleanly splits three
responsibilities across three types: `ExtensionResourcePathError` only names
and describes one failure, `ExtensionResourcePath` only resolves and checks
containment, and `InstalledContentLocation` only composes locations — none of
the three reads a manifest, parses JSON, or performs a file read
(`error-case`, `single-base-resolve`, `application-support-composition`).
`input-sanitization` passes because every `declared` string is
extension-author-supplied, untrusted text, and `resolve` never trusts it: it
is resolved, symlink-canonicalized, and checked against a component-wise
containment rule before any caller is handed a `URL` to read
(`candidate-construction`, `escape-refusal`, `symmetric-canonicalization`);
the source's own header comment names the exact vulnerability class this
closes. `explicit-error-handling` passes because the one failure this file
defines is never swallowed — it is a typed, `Equatable`,
`LocalizedError`-conforming case a caller must handle, and every production
caller (`ThemeContributionPoint`, `SnippetStore`, `ExtensionHost`) does
handle it, either recording it for display or re-throwing it as its own
richer error (`escape-refusal`, `error-message`). `unit-test-coverage`
passes: `ExtensionResourcePathTests.swift` exercises both `resolve`
overloads, the flagless-base case, the escape refusal and its message, and
the containment primitive directly (a prefix-sharing sibling, self-
containment, a deep descendant, a symlinked base, and a symlink-planted
escape), and its `InstalledContentLocationTests` suite exercises both
`InstalledContentLocation` factories and the injected-home override.
`no-hardcoded-strings` fails: `errorDescription` returns a fixed English
sentence with no localization lookup of any kind, so the message an
extension author sees when a path escapes is English regardless of the
host's locale (`error-message`, Localization).

