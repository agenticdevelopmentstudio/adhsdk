
- **SwiftUI**: no view is involved. Port `ChatBackend`/`Backend` as Swift
  `protocol`s; `EventQueue<T>` maps onto `AsyncStream<T>.makeStream()` (its
  `continuation.yield`/`continuation.finish` replace `push`/`close`, and
  `AsyncStream` is itself multi-consumer-safe if that is ever needed, unlike
  the source's `EventQueue`). `FetchBackend` becomes a `URLSession` POST with
  a per-call `Task` holding its own cancellation (rather than one shared
  field) so **fetchbackend-single-controller-field**'s concurrency gap has no
  Swift equivalent by construction. `PersonaChatBackend`'s SSE loop maps onto
  `URLSession.bytes(for:)` line-by-line parsing (or `EventSource`-style
  helper) feeding the same `AsyncStream`; `lifetime`/`controller` become two
  `Task`s (or one `Task` holding a nested child `Task`), cancelled
  independently to preserve **persona-destroy-aborts-both-controllers**.
- **Compose**: `ChatBackend`/`Backend` become Kotlin `interface`s;
  `EventQueue<T>` maps onto a `Channel<T>` (`UNLIMITED` or `BUFFERED`
  capacity) exposed as a `Flow<T>` via `receiveAsFlow()`. `FetchBackend`
  becomes an OkHttp/Ktor POST inside a per-call coroutine `Job`, cancelled
  independently per call rather than sharing one field. `PersonaChatBackend`
  parses SSE from a streaming response body inside a coroutine, using a
  `CoroutineScope`'s `Job` hierarchy for the `lifetime`/`controller` split
  (cancelling the child job cancels only the in-flight turn; cancelling the
  scope cancels everything, mirroring `lifetime.abort()`).
- **React/Web** (source platform): `packages/web/packages/chat/src/backends/*.ts`
  — plain TypeScript classes and functions with no React import; `fetch`,
  `AbortController`, `crypto.randomUUID()`, `ReadableStream`/`TextDecoder`
  (for SSE), and hand-rolled `Promise`-based queuing (`EventQueue`, the
  `tail` chain) stand in for whatever platform-native equivalents another
  port uses. The only call site, `hooks/useChatSession.ts`, wraps a
  `ChatBackend` in `ChatBackendAdapter` before use.
- **AppKit / UIKit**: the same Swift port described under SwiftUI applies
  unchanged — nothing here is UI-framework-specific; an `NSViewController`
  or `UIViewController` consumes the same `AsyncStream<InboundEvent>` a
  SwiftUI view would.
- **WinUI 3**: `ChatBackend`/`Backend` become C# `interface`s.
  `EventQueue<T>` maps onto `System.Threading.Channels.Channel<T>`
  (`Channel.CreateUnbounded<T>()`, with `Writer.TryWrite`/`Writer.Complete`
  replacing `push`/`close`, and `Reader.ReadAllAsync()` replacing `drain()`).
  `FetchBackend` becomes an `HttpClient.PostAsync` call with a per-call
  `CancellationTokenSource` (never a single reused field, avoiding
  **fetchbackend-single-controller-field**'s gap) passed as the call's
  `CancellationToken`. `PersonaChatBackend`'s SSE consumption maps onto
  reading `HttpResponseMessage.Content.ReadAsStreamAsync()` line-by-line (or
  a library such as `System.Net.ServerSentEvents` where available), exposed
  as an `IAsyncEnumerable<InboundEvent>`; `lifetime`/`controller` become two
  `CancellationTokenSource`s, one covering the whole backend's lifetime and
  one recreated per turn, `Dispose`d/cancelled independently exactly as the
  source's two `AbortController`s are.

