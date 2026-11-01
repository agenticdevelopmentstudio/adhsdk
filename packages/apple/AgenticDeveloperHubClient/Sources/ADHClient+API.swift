// ADHClient, the transports, the session and the Keychain stores live in
// AgenticDeveloperHubAuth, the sign-in tier, so an app that only signs in never
// compiles the full client. Re-exported so `import AgenticDeveloperHubClient`
// still reaches every one of them.
//
// The auth module's generated client is `HubAuthClient` (generate.py renames
// it), so `Client` here is always the full API. Both modules still generate
// `Components` and `Operations`; where both are visible, this module's own
// shadow the re-exported ones. A value returned by an ADHClient sign-in call is
// the auth module's type: name it
// `AgenticDeveloperHubAuth.Components.Schemas.User`, or let inference carry it.
@_exported import AgenticDeveloperHubAuth
import OpenAPIRuntime

extension ADHClient {

    /// The full generated typed API. Call any operation directly on this. It
    /// runs through the same transport and middleware chain as ``authAPI``
    /// and `rawJSON`, so bearer injection and refresh-and-retry apply the same.
    public var api: Client {
        Client(
            serverURL: transport.serverURL,
            transport: transport.transport,
            middlewares: middlewares
        )
    }
}
