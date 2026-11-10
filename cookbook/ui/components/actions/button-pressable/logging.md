
Subsystem: N/A | Category: N/A

No logging. `button-pressable.tsx` makes no logging or telemetry calls; state
changes are purely in-memory, and any telemetry belongs in the consumer's own
forwarded pointer handler, not in this file.

