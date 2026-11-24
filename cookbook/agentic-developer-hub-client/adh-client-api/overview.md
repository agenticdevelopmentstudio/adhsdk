
`ADHClient+API.swift` is the one file in the `AgenticDeveloperHubClient`
module that extends `ADHClient` with the whole generated typed API. `ADHClient`
itself, the transports, the session and the Keychain stores live in the sign-in
tier module, `AgenticDeveloperHubAuth`, so an app that only signs in never
compiles the full client. The file's doc comment states the split: the auth
module generates only the sign-in and session operations, exposed as
`authAPI` of type `HubAuthClient`; this module adds `api`, of type `Client`,
which is always the full API.

The file also re-exports the auth module with an exported import, so
`import AgenticDeveloperHubClient` still reaches `ADHClient`, `APITransport`,
the session and credential stores and the rest of the sign-in tier. Both
modules generate `Components` and `Operations`; where both are visible, this
module's own shadow the re-exported ones. A value returned by an `ADHClient`
sign-in call is the auth module's type, so a caller names it
`AgenticDeveloperHubAuth.Components.Schemas.User` or lets inference carry it.

The recipe covers only `api` and the module-boundary contract in that file.
The façade it hangs off is specified in
[adhsdk.ingredient.hub-client](cookbook:9041d819-d6bf-405a-9129-9730bb2c8a6b),
the transport seam in
[adhsdk.ingredient.transport](cookbook:d9dfd305-be0d-4770-9db8-43a35218c8b7),
and the credential and session types in
[adhsdk.ingredient.auth](cookbook:8b79c521-04f3-4a43-90db-ae6e0bba9f84).

