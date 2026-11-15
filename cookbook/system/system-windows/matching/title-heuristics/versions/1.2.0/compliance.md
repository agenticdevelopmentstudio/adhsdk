
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

unit-test-coverage is partial: `HeuristicTests.swift` asserts Xcode (em and
en dash), one VS Code title, and two Warp titles, but has no test for
`BraveHeuristic` or `TerminalHeuristic`, none for the VS Code generic-title
and filename branches, and none for the "Welcome — Visual Studio Code" title
whose code result contradicts its doc comment. separation-of-concerns passes
because each app's title format lives in its own type, the separator logic is
centralized in `HeuristicTitleParser`, and app-name lookup and scoring stay in
`HeuristicRegistry` and `SystemWindowMatcher`. explicit-error-handling passes
because the only failure mode — no extractable pattern — is expressed in the
return type as `nil`, and the caller handles it explicitly with a documented
fallback. no-hardcoded-strings fails because each heuristic's user-visible
`name` is an English literal with no localization lookup, and the Brave and
VS Code parsing literals only recognize English application titles (see
Localization).

