
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.test-pyramid](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/203de556-83a8-5211-acaf-155c49da0eb3) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Notes: separation-of-concerns passes because the policy is kept at toolkit level specifically so enforcement (`LocalInferenceGuard`) and presentation (`ModelChooserContent`/`ModelChooserViewController`) each consume the same pure computation rather than each reimplementing it, per the Overview's "so every `AIPluginKit` host shares one representation... and the two cannot drift." unit-test-coverage passes because `ModelFitPolicyTests.swift` covers tier boundaries, verdict precedence, and every `fitInfo`/`pickerLabel` text format across 20 vectors. test-pyramid passes because `ModelFitPolicyTests.swift` tests the pure functions entirely at the unit level, with no integration or UI layer needed for a case-less policy enum. no-hardcoded-strings fails because every string `ModelFitPolicy` produces — `gbString`, `footprintDescription`, `fitInfo.text`, `pickerLabel`, and `verdict`'s reasons — is a hardcoded English literal composed inline with no localization key, and that text is shown verbatim by the macOS model picker.

