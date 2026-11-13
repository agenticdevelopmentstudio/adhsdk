
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| relative-date-001 | relative-when-recent, units-style | now − 3 hours, `en_US`, full | `3 hours ago` (test: recentIsRelative). |
| relative-date-002 | units-style | now − 3 hours, `en_US`, default style | `3h ago` (test: defaultStyleIsAbbreviated). |
| relative-date-003 | absolute-when-old, default-cutoff | 2026-11-01 against now 2026-11-13, `en_US` | `Nov 1, 2026` (test: olderThanAWeekIsAbsolute). |
| relative-date-004 | cutoff-boundary | now − exactly 7 days, `en_US`, full | `1 week ago`; one second earlier, `Nov 6, 2026` (test: exactlyTheCutoffIsRelative). |
| relative-date-005 | no-cutoff | now − 400 days, `en_US`, full, no cutoff | `1 year ago` (test: noCutoffIsAlwaysRelative). |
| relative-date-006 | future-is-relative | now + 30 days, `en_US`, full | `in 1 month` (test: futureIsRelative). |

