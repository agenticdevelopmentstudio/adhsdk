
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: edits, repricing and titles are pure helpers; money arithmetic and rate parsing are the shared money utilities and the daemon owns the stamps. unit-test-coverage is partial: `BillingDTOEditingTests` covers `replacing`, clearing, `repriced` and the record titles and labels, but no test asserts the rate-text parsing range.

