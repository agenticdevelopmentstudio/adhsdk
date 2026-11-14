
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| digest-hex-001 | lowercase, two-digits-per-byte, byte-order | `SHA256.hash(data: Data("abc".utf8)).hexString` (test: sha256OfAKnownStringIsItsLowercaseHex). | `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`. |
| digest-hex-002 | two-digits-per-byte | `SHA256.hash(data: Data()).hexString` (derived from the source; no test). | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`, 64 characters. |
| digest-hex-003 | extension-scope, two-digits-per-byte | `Insecure.SHA1.hash(data: Data("abc".utf8)).hexString` (derived from the source; no test). | `a9993e364706816aba3e25717850c26c9cd0d89d`, 40 characters. |
| digest-hex-004 | extension-scope | `Insecure.MD5.hash(data: Data("abc".utf8)).hexString` (derived from the source; no test). | `900150983cd24fb0d6963f7d28e17f72`, 32 characters. |
| digest-hex-005 | lowercase, byte-order, two-digits-per-byte | `SHA512.hash(data: Data("abc".utf8)).hexString` (derived from the source; no test). | `ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f`, 128 characters, no upper-case letter. |
| digest-hex-006 | two-digits-per-byte | `Insecure.MD5.hash(data: Data("a".utf8)).hexString` (derived from the source; no test). | `0cc175b9c0f1b6a831c399e269772661`, 32 characters: the first byte 0x0c renders as `0c`, keeping its leading zero. |
| digest-hex-007 | pure | Call `hexString` twice on one digest value (derived from the source; no test). | Both calls return identical strings. |

