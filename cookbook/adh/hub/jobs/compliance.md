
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |

Each check was read against the package and the data client:
- `separation-of-concerns`: transport in the data client, mapping in `mappers.ts`, topics in their own
  plain-data module (`jobs-topics.ts`), and the shared pane pieces in `job-ui.tsx`.
- `unit-test-coverage`: `partial`. The package's `__tests__/` carry the pane vectors, but they were
  written in phase 9 without being run, so they are not yet known to pass.
- `error-response-handling`: `JobsReadError` shows and reports a failed read, `refusalText` and
  `describeStepProblem` show the refusal messages, and `isJobsOff` reads the switch-off 404.
- `secure-storage`: an inbound secret and an environment token reach the page only through
  `OnceShownSecretDialog`, held in component state and dropped when it closes.
- `semantic-markup`: the status pane is a native `<table>`, and every status badge shows its status as text.
- `caching-strategy`: one query key per list from `jobsKeys`, invalidated after each write.
