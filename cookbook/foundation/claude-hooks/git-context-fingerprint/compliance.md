
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: running commands lives in `ReadOnlyGit`, and this type decides what is sampled, hashes it and splices the result. unit-test-coverage is partial: `GitContextFingerprintTests` covers sampling, hash movement, the untrimmed status, nesting, byte preservation and every fallback, but nothing exercises a failing status or log command after the branch resolved, and vectors 013 to 017 (entry count, `sampled_at` form, the five-commit limit, the empty object and the directory scope) have no test yet.

