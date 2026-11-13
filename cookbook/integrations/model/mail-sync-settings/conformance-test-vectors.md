
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-sync-settings-001 | default-values | Read `MailSyncSettings.default` (test `defaultValues`) | Three flags false, `windowDays` 30, `pollIntervalMinutes` 15 |
| mail-sync-settings-002 | memberwise-init-defaults | `MailSyncSettings()` | Equals `default` |
| mail-sync-settings-003 | allows-filed, allows-flagged | `default.allows(.filed)`, `.archived`, `.spam`, `.trash` (test `allows`) | true, false, false, false |
| mail-sync-settings-004 | allows-flagged | All three flags set true, query `.archived`, `.spam`, `.trash` (test `allows`) | true for each |
| mail-sync-settings-005 | validated-window | `windowDays` 0, then 3651, with `pollIntervalMinutes` 15 (test `rejects`) | Each throws `IntegrationError.invalidSettings` with message `windowDays must be 1–3650, got 0`, then `... got 3651` |
| mail-sync-settings-006 | validated-poll | `pollIntervalMinutes` 0, then 1441, with `windowDays` 30 (test `rejects`) | Each throws `IntegrationError.invalidSettings` with message `pollIntervalMinutes must be 1–1440, got 0`, then `... got 1441` |
| mail-sync-settings-007 | validated-returns-self | `default`; then (3650, 1440); then (1, 1) (test `accepts`) | `validated()` returns an equal value each time, no throw |
| mail-sync-settings-008 | decode-lenient | JSON `{}` (test `lenientDecode`) | Decodes to `default` |
| mail-sync-settings-009 | decode-partial, decode-keys | JSON `{"includeSpam":true,"windowDays":10}` (test `partialDecode`) | `includeSpam` true, `windowDays` 10, `pollIntervalMinutes` 15 |
| mail-sync-settings-010 | validated-window, validated-order | `windowDays` 0 and `pollIntervalMinutes` 0 | Throws with message `windowDays must be 1–3650, got 0` (derived from the source, no test) |
| mail-sync-settings-011 | decode-no-range-check | JSON `{"windowDays":5000}` | Decodes with `windowDays` 5000; `validated()` then throws (derived from the source, no test) |
| mail-sync-settings-012 | decode-wrong-type | JSON `{"windowDays":"x"}` | Decoding throws a `DecodingError` (derived from the source, no test) |
| mail-sync-settings-013 | decode-null-key | JSON `{"windowDays":null}` | `windowDays` is 30 (derived from the source, no test) |
| mail-sync-settings-014 | decode-ignore-unknown | JSON `{"foo":1}` | Decodes to `default` (derived from the source, no test) |
| mail-sync-settings-015 | validated-window | `windowDays` -1, with `pollIntervalMinutes` 15 | Throws with message `windowDays must be 1–3650, got -1` (derived from the source, no test) |
| mail-sync-settings-016 | validated-poll | `pollIntervalMinutes` -1, with `windowDays` 30 | Throws with message `pollIntervalMinutes must be 1–1440, got -1` (derived from the source, no test) |
