// HubError, the session and sign-in live in AgenticToolkitHubAuth, the hub's
// login tier, so an app that only signs in links that and nothing above it.
// Re-exported so every importer of this framework (and of HubService and
// HubUI, which import this) still reaches them under their old names.
@_exported import AgenticToolkitHubAuth
