
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the file only assembles text from job data; running jobs, timers and the tools themselves live elsewhere in the partner feature. `unit-test-coverage` is partial: `AgenticDeveloperHubSDKCoreTests/Partner/PartnerBasePromptTests.swift` covers the enabled-only job sections, step lines and conditions, the code-review note, the git rule, the tool names and key phrases, the button-message phrases, YAML quoting of the job name and the skill frontmatter, but not an empty job list, whitespace-only conditions, job order or the base section order, which are vectors 009 to 017 and are marked untested in the vector table. `input-sanitization` is partial because the job name is escaped for the skill description while the job id, step fields and guidelines are inserted unescaped.

