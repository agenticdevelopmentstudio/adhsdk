
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

`separation-of-concerns` passes because the two files hold only the policy model and the stored settings, while mirroring, launch reopen, and presentation live in `WindowManager` and `GeneralSettingsPanelViewController`. `unit-test-coverage` passes: `ReopenOnLaunchPolicyTests` covers all six `shouldReopen(systemDefault:)` combinations, every `displayName`, and the case count, and `WindowManagerRecentsTests` covers the explicit and Combine-driven mirroring of `recentWindowsCount`. `no-hardcoded-strings` fails because `displayName` returns English literals shown to the user. `data-integrity` is partial because `recentWindowsCount` accepts any integer and passes it to AppKit unchecked outside the settings stepper's 0 to 50 range, and an undecodable stored policy silently falls back to `.useSystem`.

