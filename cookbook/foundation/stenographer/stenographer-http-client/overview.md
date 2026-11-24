
`StenographerHTTPClient` is the implementation of the `StenographerDaemonService` protocol ([adhsdk.ingredient.foundation.stenographer.stenographer-daemon-service](cookbook:96f73261-cf32-42cc-92f3-f8b58542382a)) that talks to the Stenographer daemon over its loopback HTTP API. It uses the same routes the `steno` command-line tool uses. Every request and reply is JSON in the `StenographerWire` spelling ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37): snake_case keys, ISO-8601 dates), with one deliberate exception for the provider registry push.

The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerHTTPClient.swift`, a `public final class` that is `@unchecked Sendable` and guards its mutable state with an `NSLock`. The default base URL comes from `StenographerIdentifiers` ([adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43)).

The client is built for callers that must keep working when the daemon is down. A refused connection, a non-2xx status or a body that does not decode all read the same way: `nil` for a read, `false` for a write. The one exception is a 404 on a single session, which is a real answer ("no such session"). Summarizing a session is the other exception: it throws, so the daemon's own reason can reach the user.

The daemon has no push channel to a client that is not an XPC subscriber, so the client also offers `onReconnect`: it polls `/health` and treats an `uptime` that went down as a daemon restart.

