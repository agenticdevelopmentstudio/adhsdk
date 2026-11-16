
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| executable-locator-001 | path-first, first-executable-wins | PATH `/custom/one:/custom/two`; executable: `/custom/one/gh`, `/custom/two/gh`, `/opt/homebrew/bin/gh` | `/custom/one/gh`, and only that path tested (test: pathEntriesComeFirstInOrder). |
| executable-locator-002 | path-first | PATH `/custom/one:/custom/two`; executable: `/custom/two/gh`, `/opt/homebrew/bin/gh` | `/custom/two/gh` (test: laterPathEntryWinsOverExtraDirectories). |
| executable-locator-003 | extra-directories-after, default-extras | PATH `/usr/bin:/bin`; executable: `/usr/local/bin/gh` | `/usr/local/bin/gh`, after testing `/usr/bin/gh`, `/bin/gh`, `/opt/homebrew/bin/gh` (test: extraDirectoriesAreSearchedAfterPath). |
| executable-locator-004 | extra-directories-after | no PATH; executable: `/opt/homebrew/bin/gh` | `/opt/homebrew/bin/gh` (test: extraDirectoriesAloneWithoutPath). |
| executable-locator-005 | de-duplicated | PATH `/usr/bin:/opt/homebrew/bin/::/usr/bin` | `searchDirectories` is `/usr/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, `/bin`, each tested once (test: repeatedDirectoriesAreSearchedOnce). |
| executable-locator-006 | nil-when-absent | PATH `/usr/bin`; executable: `/usr/bin/git` | `find("gh")` is nil (test: nilWhenAbsent). |
| executable-locator-007 | bare-name-only | `find("")`, `find("bin/gh")` | nil, no path tested (test: nameWithSlashOrEmptyFindsNothing). |
| executable-locator-008 | de-duplicated | PATH `.:bin:/usr/bin`; executable: `./gh`, `bin/gh` | `searchDirectories` starts at `/usr/bin`, and `find(\"gh\")` is nil (test: relativeEntriesAreDropped). |

