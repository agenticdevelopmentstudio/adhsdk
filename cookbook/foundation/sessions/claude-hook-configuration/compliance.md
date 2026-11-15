
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: this type only carries values and derives paths, while reading and editing `settings.json` is `ClaudeHookInstaller`'s job, status-line files are `ClaudeStatusLine`'s and drop writing is `HookDropWriter`'s. unit-test-coverage is partial: `ClaudeHookConfigurationConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Sessions/ClaudeHookConfigurationConformanceTests.swift`) tests 20 of 22 vectors, and the installer tests cover the rest of the helper path and marker files. Vectors 017 (the default executable traps, which would crash the runner) and 018 (the home directory cannot be changed inside a test process) are skipped.

