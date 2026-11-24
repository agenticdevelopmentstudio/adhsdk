
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: this is the seam that keeps rules in the shared tier and storage in the host. unit-test-coverage is partial: `BillingPersistenceConformanceTests` names all nine vectors and skips each one, because the guard, transaction and cursor semantics belong to the host's SQLite store (`DatabaseManager`), which is outside this repository, and a fake would only assert its own code. It tests the value types the contract defines (session row, segment context, stored entry, overwrite guards).

