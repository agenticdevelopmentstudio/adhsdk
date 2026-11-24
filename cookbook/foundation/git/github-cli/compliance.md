
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |

`separation-of-concerns` passes because the client only runs `gh` and decodes its answers; finding the executable is `ExecutableLocator`'s and recording is the command log's. `unit-test-coverage` passes: `GitHubCLITests` (`Tests/AgenticDeveloperHubSDKCoreTests/Git/GitHubCLITests.swift`) covers all 21 vectors with a stub runner. `input-sanitization` passes because a dash-led or empty branch and a non-positive number are refused before anything runs, and arguments are passed as an argument vector, never through a shell.

