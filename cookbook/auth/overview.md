
`hub-client-auth` is the authentication subsystem of the hub client's Swift
framework target (`Sources/Auth/`), supporting macOS 14.0+ and iOS 17.0+
(`project.yml`). It has no visual
surface: it is a set of value types (`Credentials`, `Session`), storage
protocols and concrete stores (Keychain-backed and in-memory), and two
`ClientMiddleware` implementations — `AuthenticationMiddleware` (bearer-only)
and `SessionRefreshMiddleware` (bearer plus transparent refresh-and-retry) —
that `ADHClient` attaches to every outgoing request. A thin set of convenience
wrappers on `ADHClient` (`login`, `createAPIToken`, `adopt`, `logout`, `signIn`,
`completeMfa`, `sendMfaSms`, passkey and OAuth-exchange flows, `signOut`,
`currentUser`) drive these stores and surface typed outcomes and errors instead
of the generated OpenAPI request/response shapes. This recipe covers exactly
the nine files under `Sources/Auth/`; `ADHClient` itself, its transports, and
`rawJSON` are referenced only where the Auth files call into them.

