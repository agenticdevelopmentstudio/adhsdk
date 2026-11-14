
Not applicable: neither `ADHClient.swift` nor `ADHClient+Raw.swift` defines a
flag or feature-toggle field; every code path in these two files runs
unconditionally. (Transport selection can be steered by
`TransportResolver.fromUserDefaults(_:port:)`'s `useDirectMode` key, but that
steering lives in `TransportResolver.swift` — `hub-client-transport`'s
contract, not either of the two sources this recipe covers.)

