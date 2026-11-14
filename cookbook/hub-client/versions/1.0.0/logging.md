
Not applicable: no log, print, or diagnostic-emission call appears anywhere
in `ADHClient.swift` or `ADHClient+Raw.swift`; every failure is communicated
to the caller by throwing a typed `RawRequestError` (or whatever error the
transport/middleware itself throws), never by writing to a log.

