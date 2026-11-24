
Subsystem: process `console` | Category: telemetry

| Event | Level | Message |
|-------|-------|---------|
| A GlitchTip issues page returned a non-`ok` HTTP response | warn | `` [telemetry] GlitchTip issues HTTP <status> `` |
| A GlitchTip issues page body parsed but was not an array | warn | `[telemetry] GlitchTip issues returned a non-array body — treating as a failed poll` |
| The GlitchTip issues walk timed out | warn | `` [telemetry] GlitchTip issues fetch timed out after <TIMEOUT_MS>ms `` |
| A GlitchTip issues request threw a non-timeout error | warn | `` [telemetry] GlitchTip issues fetch failed: <message> `` |
| GlitchTip re-read of page 1 failed after a multi-page walk | warn | `[telemetry] GlitchTip issues re-read of page 1 failed — reporting the walk incomplete` |
| The PostHog KPI query failed | warn | `` [telemetry] PostHog poll failed (<error>) `` |

