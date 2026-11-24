
No test sits beside the source file. Vectors 004 to 009 come from the tests that exercise these constants through the daemon (`DaemonSessionSummarizerTests`, `PreferencesServiceTests`); the rest follow from the source's own values and logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| summary-preference-dt-os-001 | character-cap-formula | `characterCap(maxWords: 8)` and `characterCap(maxWords: 4)` | 80 for each, because ten times the words is below 80 |
| summary-preference-dt-os-002 | character-cap-formula | `characterCap(maxWords: 20)` | 200 |
| summary-preference-dt-os-003 | character-cap-formula | `characterCap(maxWords: 8)` against `characterCap(maxWords: 9)` | 80, then 90: the floor ends above 8 words |
| summary-preference-dt-os-004 | clamp-contract, clamp-both-sides | `PreferencesService.setSummary(maxWords: Int.max)` (`testSummaryNumbersAreClamped`) | the response's `maxWords` equals `SummaryLimits.maxWords.upperBound`, 20 |
| summary-preference-dt-os-005 | clamp-contract, daemon-fallback | settings rows `ai_summary_max_words` = `999` and `ai_summary_activity_lines` = `0` (`testSummaryPrefsClampOutOfRangeStoredValues`) | `SummaryPrefs.maxWords` is 20 and `SummaryPrefs.activityLines` is 10 |
| summary-preference-dt-os-006 | daemon-fallback | `ai_summary_timeout_seconds` = `not a number` (`testSummaryPrefsClampOutOfRangeStoredValues`) | `SummaryPrefs.timeoutSeconds` is 60, the default |
| summary-preference-dt-os-007 | daemon-fallback, default-max-words, default-interval-minutes | an empty settings table (`testSummaryPrefsFallBackToTheSharedDefaults`) | every `SummaryPrefs` accessor returns its `SummaryDefaults` value, the prompt included |
| summary-preference-dt-os-008 | placeholder-substitution-site, placeholder-dropped | prompt `Write {maxWords} words, tops.` with max words 12, then prompt `Write a title.` (`testResolvedPromptSubstitutesTheWordCap`) | `Write 12 words, tops.`, then `Write a title.` unchanged |
| summary-preference-dt-os-009 | max-words-double-duty | `cleanSummary` of a thirteen-word reply with `maxWords: 4`, then 20 (`testCleanSummaryCapsAtTheConfiguredWordCount`) | `fixing the sessions window`, then the reply unchanged |
| summary-preference-dt-os-010 | clamp-contract | `clamp(3, to: 4...20)`, `clamp(12, to: 4...20)`, `clamp(25, to: 4...20)` | 4, 12, 20 |
| summary-preference-dt-os-011 | settings-key-names | `SummarySettingsKeys.timeoutSeconds` | `ai_summary_timeout_seconds` |
| summary-preference-dt-os-012 | limit-max-words, limit-activity-lines, limit-detail-chars, limit-interval-minutes, limit-max-per-run, limit-timeout-seconds | the six `SummaryLimits` ranges | 4...20, 10...400, 40...500, 1...240, 1...50, 10...600 |
| summary-preference-dt-os-013 | default-prompt, placeholder-token | count of `{maxWords}` in `SummaryDefaults.prompt` | 1, in the first sentence |
| summary-preference-dt-os-014 | defaults-inside-limits | each default against its range | 8, 60, 120, 5, 5 and 60 each inside their ranges |
| summary-preference-dt-os-015 | default-prompt-single-line | `SummaryDefaults.prompt.contains("\n")` | false |

