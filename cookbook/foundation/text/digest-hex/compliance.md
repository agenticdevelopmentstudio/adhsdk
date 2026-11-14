
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the extension only renders bytes as text; hashing and storing the string belong to its callers. unit-test-coverage is partial: `DigestHexTests` asserts the SHA-256 of `abc`, which exercises lowercase letters and the byte order, but nothing asserts the leading zero of a byte below 0x10, the empty-data digest, or a digest type other than SHA-256.

