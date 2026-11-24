
Derived from `HookCaptureTests` where a test is named, and from the source otherwise.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| drop-001 | variable-name, variable-per-configuration | Configurations named `stenographer` and `adkd` (test `testEachConfigurationReadsItsOwnDropDirectoryVariable`) | `STENOGRAPHER_DROP_DIR` and `ADKD_DROP_DIR` |
| drop-002 | variable-name | A configuration named `my-app.v2` | `MY_APP_V2_DROP_DIR` |
| drop-003 | variable-name | A configuration named `café` | `CAF__DROP_DIR` (the accented letter is not ASCII, so it becomes `_`) |
| drop-004 | variable-empty-name | A configuration named with the empty string | `_DROP_DIR` |
| drop-005 | override-wins | Configuration `adkd`, environment `ADKD_DROP_DIR=/tmp/x` (test `testTheVariableOverridesTheConfiguredDirectoryOnlyWhenNonEmpty`) | `/tmp/x` |
| drop-006 | empty-override-ignored, tilde-preserved | Configuration `adkd`, environment `ADKD_DROP_DIR=` (empty) | `~/.claude/adkd-events`, unexpanded |
| drop-007 | other-variable-ignored | Configuration `adkd`, environment `STENOGRAPHER_DROP_DIR=/tmp/y` (same test) | `~/.claude/adkd-events` |
| drop-008 | empty-override-ignored | Configuration `adkd`, empty environment | `~/.claude/adkd-events` |
| drop-009 | directory-created, json-encoding, file-name, atomic-publish | `writeDropFile` of an envelope with event `Stop` into a directory that does not exist (`testRunWritesADropFileForTheEvent` asserts the file count and the event; the rest follows from the source) | The directory exists afterwards; it holds exactly one file ending in `.json` (asserted by the test) and no `.tmp` file; the name matches the pattern of digits, a hyphen, eight lowercase hex characters, and `.json`; the file is one line of compact JSON that parses as an object whose `event` is `Stop` (asserted by the test) |
| drop-010 | tilde-expansion | `writeDropFile` with directory `~/drop-test` (no test; derived from the source) | The file is created under the user's home directory, not in a directory literally named `~` |
| drop-011 | unique-names | Two `writeDropFile` calls in quick succession into one directory | Two distinct `.json` files |
| drop-012 | errors-thrown | `writeDropFile` with a directory path whose parent is a regular file | Throws; no file is created |
| drop-013 | errors-thrown, directory-created | `writeDropFile` into an existing directory twice | Both calls succeed; two files |
| drop-014 | no-overwrite, temp-left-on-move-failure | A file with the chosen final name already exists when the move runs (source inspection only today; with an injected clock and suffix source, pre-create that name) | The move throws and the `.tmp` file remains |
| drop-015 | atomic-publish | A scanner lists the directory for `.json` files while a write is in progress (source inspection only; it cannot be reproduced deterministically) | It never sees a partial file; only complete `.json` files or the `.tmp` name |
| drop-016 | override-wins, directory-created | `StatusLineCapture.feed` with `ADKD_DROP_DIR` set and `post` returning false (test `testAFeedTheDaemonRefusesIsDroppedInTheConfigurationsDirectory`) | One drop file with event `StatusLine` appears in the override directory |
| drop-017 | environment-default | `dropDirectory` called without an `environment` argument while the process environment holds the configuration's override variable | The override value is returned |
| drop-018 | stateless | Twenty `writeDropFile` calls from concurrent threads into one directory | Twenty distinct `.json` files, no errors |

SHOULD requirement `production-no-override` has no vector: it constrains how hooks are installed, not what this code returns, and its rationale is the third entry under Design Decisions. The open question on `envelope-serializable` has no vector because the behavior it asks about is undefined.

