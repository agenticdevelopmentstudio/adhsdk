
Not applicable: no log, print, or diagnostic-emission call appears anywhere
in `ADHSyncAPI.swift`; every failure is communicated to the caller by
throwing a typed `Failure` value, never by writing to a log.

