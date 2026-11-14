
The source has no test file for the setting itself; an implementer should add a `UserSettings+FileBrowser` test that asserts vectors 001 to 003, 007 and 012 (the key, the default, the secure flag, the unchanged round trip and the shared declaration). The vectors below are traced to the declaration and to the settings-storage contract it inherits. The pattern-semantics vectors are traced to `GitIgnoreMatcherTests` and show what a stored list means to the code that consumes it.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| user-settings-file-browser-001 | setting-key-name | Read the setting's `name` | `file_browser.excluded_patterns` |
| user-settings-file-browser-002 | setting-default-empty, setting-value-type | Read `defaultValue` | The empty list of strings |
| user-settings-file-browser-003 | setting-not-secure | Read `isSecure` | `false` |
| user-settings-file-browser-004 | inherits-settings-storage, no-migration | Read `currentValue` on a store holding nothing under the key | The empty list |
| user-settings-file-browser-005 | inherits-settings-storage | Set `value` to `["*.log", "build/"]`, then read `currentValue` | The list `["*.log", "build/"]` in that order, and the key name `file_browser.excluded_patterns` appears on the change stream |
| user-settings-file-browser-006 | inherits-settings-storage | Store holds bytes under the key that are not a list of strings, then read | The empty list, no error |
| user-settings-file-browser-007 | entry-no-validation, entry-duplicates-allowed | Set `value` to `["a", "a", ""]` and read it back | `["a", "a", ""]` unchanged: no trimming, no deduplication, no dropping of the blank entry |
| user-settings-file-browser-008 | entry-order-significant, entry-gitignore-syntax | List `["*.log", "!keep.log"]` given to `GitIgnoreMatcher`; test `testNegationAndLastMatchWins` | `a.log` excluded, `keep.log` not excluded |
| user-settings-file-browser-009 | entry-order-significant | List `["!keep.log", "*.log"]` given to `GitIgnoreMatcher`; test `testNegationAndLastMatchWins` | `keep.log` excluded: the later pattern wins |
| user-settings-file-browser-010 | entry-no-validation, entry-gitignore-syntax | List `["", "   ", "# *.log"]` given to `GitIgnoreMatcher`; test `testBlankLinesAndCommentsAreIgnored` | The matcher is empty and `a.log` is not excluded |
| user-settings-file-browser-011 | entry-gitignore-syntax | List `["*.log"]`; test `testUnanchoredNameMatchesAtAnyDepth` | `a.log` and `deep/er/a.log` excluded, `a.log.txt` not excluded |
| user-settings-file-browser-012 | setting-shared-instance | Two readers each access `UserSettings.fileBrowserExcludedPatterns` | Both receive the same declaration, so a write through one is the value the other reads |

