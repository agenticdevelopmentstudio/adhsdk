
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |

`separation-of-concerns` passes: parsing (`AppHeuristic`, `HeuristicTitleParser`), user rules, persistence (`CustomHeuristicStore`), lookup (`HeuristicRegistry`) and scoring/assignment (`SystemWindowMatcher`) are separate types, and applying match results is left to `SystemWindowContextManager`. `unit-test-coverage` is partial: `SystemWindowMatcherTests` covers the app gate, appOnly, the substring length guard, substring and regex scoring, the display bonus, threshold filtering, deterministic ties and `MatchResult` equality, and `HeuristicTests` covers the separators, custom-rule fingerprinting and `isBuiltIn`; nothing tests `CustomHeuristicStore`, `.appAndTitleExact` scoring, the fingerprint fallback, invalid regexes or `registerCustomRules` replacement. `explicit-error-handling` passes because store failures are thrown to the caller and invalid regexes are logged rather than swallowed. `no-hardcoded-strings` fails because `CustomMatchMode.displayName` and the default rule name are English literals shown in Settings. `data-integrity` is partial because rules are never validated: an invalid regex or empty app name is accepted and saved, and two rules for the same app leave one silently unused. `no-pii-in-logs` passes because only the user-authored regex pattern is logged, never a window title.

