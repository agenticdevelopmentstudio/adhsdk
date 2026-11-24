
Not applicable: none of `APITransport.swift`, `DaemonContract.swift`, or
`TransportResolver.swift` registers or resolves an app URL scheme or
universal link — the URLs they build (`backendURL`, `daemonURL`,
`healthURL`) are outbound API endpoints, not inbound deep links.

