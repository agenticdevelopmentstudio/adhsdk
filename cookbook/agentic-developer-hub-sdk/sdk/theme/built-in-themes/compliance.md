
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The catalogue does one job: it holds color data and looks it up by ID, while persistence, palette derivation and display live in other types, so separation of concerns passes. `BuiltInThemesTests` covers the count, unique IDs, palette validity, chrome overrides, legibility, the default ID and hex accuracy, and `BuiltInThemesConformanceTests` (`BuiltInThemesConformanceTests.swift`) covers the composition, lookup miss, case-sensitive match, hit, hand-authored order, opacity and chrome builder vectors, so unit-test coverage is partial: vectors built-in-themes-016 and built-in-themes-017 are skipped because the `rgb` helper is private and an invalid literal halts the process, which a unit test cannot observe. Error handling is partial because a malformed literal halts the process by design instead of returning an error, which is explicit and documented but not recoverable. The no-hardcoded-strings check is partial because theme names and attributions are English literals; they are proper nouns, but they are not externalized.

