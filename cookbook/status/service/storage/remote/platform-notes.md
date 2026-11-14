
- **SwiftUI**: Use an `actor` that owns the store and serves calls from a `Task` queue; actor isolation gives the one-at-a-time rule, and the client can be a `Sendable` wrapper that calls `await actor.method(...)`. Errors cross as `Error` values, so no flattening is needed in process.
- **Compose**: Use a single-thread `CoroutineDispatcher` (or a `Mutex`) around the store for the FIFO rule, and a `Channel` of request objects when the clients run in other processes. Throwable causes are available on the JVM as is.
- **React/Web**: In a browser use a Web Worker with a `MessageChannel`; the same shape handshake and id-matched replies apply. In Node keep `worker_threads` as in the source.
- **AppKit / UIKit**: Use a serial `DispatchQueue` that owns the store and `async` wrappers over it; a serial queue gives the FIFO rule.
- **WinUI 3**: Use a `System.Threading.Channels.Channel<Call>` with one reader loop as the single queue, and `TaskCompletionSource<object?>` per call id on the client. Serialise values with `System.Text.Json` when crossing a process boundary, and flatten exceptions to `name`, `message`, `HResult` as the code, and the `InnerException` chain. In an ASP.NET Core host the database owner is an `IHostedService` that reads the channel.

