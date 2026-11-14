
Derived from `MCPBearerTokenTests` where named; the rest are traced to the source. File paths are in a fresh temporary directory.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcp-bearer-token-001 | generate-length, generate-alphabet, generate-fresh | `generate()` twice (`testGenerateIs64HexCharacters`) | Each has 64 characters, all hexadecimal; the two differ |
| mcp-bearer-token-002 | load-creates, load-creates-directory, file-mode-created, load-stable | `load(from:)` twice on a path whose directory does not exist (`testLoadCreatesTheFileWithMode600AndIsStable`) | Both calls return the same token; the file's mode is 0600 |
| mcp-bearer-token-003 | load-tightens, load-reads-existing, load-no-format-check | File holds `keepme` with mode 0644 (`testLoadTightensAWiderExistingFileAndKeepsItsToken`) | Returns `keepme`; the file's mode is now 0600 |
| mcp-bearer-token-004 | load-trims | File holds `abc123` and a line feed (`testLoadReadsAnExistingTokenTrimmed`) | Returns `abc123` |
| mcp-bearer-token-005 | error-unwritable, error-no-partial-token | Path `/dev/null/cannot/mcp-token` (`testTokenLoadFailureIsThrown`) | Throws an error |
| mcp-bearer-token-006 | refuse-non-regular, refuse-link-target-untouched, error-unreadable | Symbolic link at the path pointing to a file holding `not-a-token` (`testASymlinkAtTheTokenPathIsRefused`) | Throws; the target file still holds `not-a-token` |
| mcp-bearer-token-007 | refuse-dangling-link | Symbolic link at the path pointing to a missing file (`testASymlinkAtTheTokenPathIsRefused`) | Throws; the missing target is not created |
| mcp-bearer-token-008 | load-regenerates-empty | File holds only spaces and a line feed | Returns a 64-character token and the file now holds it |
| mcp-bearer-token-009 | load-leaves-narrow | File holds `abc` with mode 0400 | Returns `abc`; the mode is still 0400 |
| mcp-bearer-token-010 | refuse-non-regular | A directory at the path | Throws `LoadError.unreadable` |
| mcp-bearer-token-011 | error-descriptions | Throw from a read failure and a write failure | Descriptions start `could not read <path>: ` and `could not write <path>: ` |
| mcp-bearer-token-012 | file-no-newline, write-truncates | Missing file, then read its bytes | Exactly 64 bytes, no line feed |
| mcp-bearer-token-013 | token-revocation, token-lifetime | Load, delete the file, load again | The second token differs from the first |
| mcp-bearer-token-014 | load-directory-mode | Directory with mode 0755 holding a wider token file | After `load(from:)` the directory is still 0755 |
| mcp-bearer-token-015 | generate-crash-on-failure, generate-entropy, write-no-follow, write-chmod, token-not-logged, violation-handling, error-unreadable, error-unwritable, load-reads-existing | Not testable without injecting a failing random source, or racing a link into place after the check; asserted from the source comments and calls | No test exists for these; the source's `precondition` and the `O_NOFOLLOW` open flag are the evidence |

