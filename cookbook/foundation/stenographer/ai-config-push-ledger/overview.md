
`AIConfigPushLedger` remembers which AI provider configuration ids one host has pushed to the daemon. A later push uses it to name exactly the configurations it dropped (`AIProviderConfigSync.removedConfigIds`), instead of asking the daemon to delete everything it was not sent.

Two hosts share one daemon registry: the Kitchen over HTTP and the Stenographer app over XPC. Each keeps its own ledger under its own `key`, so neither ever deletes a configuration it did not push itself. The ledger is a `Sendable` struct over `UserDefaults`, which stores the ids as a sorted array of UUID strings under the ledger's key.

