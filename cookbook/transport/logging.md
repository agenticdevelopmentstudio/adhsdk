
`APITransport.swift`, `DaemonContract.swift`, and `TransportResolver.swift`
emit no log calls — no `os_log`, `Logger`, or `print` statement appears in
any of the three files. `TransportResolver.cachedKind` and
`ADHClient.transportKind` (outside this component's file set) expose the
current decision for a caller to log if it chooses to, but no logging
subsystem or category is defined by this source.

