
Subsystem: `@adh-sdk` | Category: `editing`

| Event | Level | Message |
|-------|-------|---------|
| Layout fault detected | error | `[@adh-sdk/editing] <fault text>` — once per fault, each time the fault list changes (an effect keyed on the memoized `layoutFaults`, so not on every render) (`container.tsx`). |
| Repair produced a still-invalid value | error | `[@adh-sdk/editing] repair() left a value still invalid — <key>: <message>[; <key>: <message> ...]` (`container.tsx`). |

