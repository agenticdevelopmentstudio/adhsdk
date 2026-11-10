
- **SwiftUI**: This is the source: `PersonaChatCoordinator.swift` and
  `SSEParser.swift`, plain `Foundation` with no SwiftUI dependency at all —
  no `@Observable`, no `View`, no SwiftUI-specific types anywhere in either
  file. A SwiftUI host binds to it only indirectly, through a view model
  (e.g. `ObservableChatViewModel`) that subscribes to `inboundEvents`.
- **Compose**: Start from `kotlinx.coroutines` and `kotlinx.serialization`.
  `AsyncStream<InboundEvent>` maps to a `kotlinx.coroutines.flow.Flow`, or a
  `Channel<InboundEvent>` if buffering semantics need to match
  `.unbounded`. `SSEParser`'s buffered block reader ports directly (Kotlin
  has no built-in SSE parser either). The actor's single-writer guarantee
  has no direct Kotlin analogue — use a single-threaded `CoroutineDispatcher`
  or a `Mutex` guarding `conversationID`/`openInvocations` — and
  `TurnControl`'s `NSLock` becomes a `kotlinx.atomicfu` `AtomicRef`/`Mutex`
  pair holding a cancellable `Job` instead of a `Task`.
- **React/Web**: The toolkit already ships a TypeScript counterpart to this
  exact spec, `PersonaChatBackend.ts`
  (`packages/web/packages/chat/src/backends/`) — start there rather than
  re-deriving the contract. It replaces `URLSession.bytes(for:)` with
  `fetch` plus a `ReadableStream` reader, replaces `AsyncStream` with a
  plain event emitter or async generator, and needs no actor-equivalent
  lock at all, since JavaScript's single-threaded event loop already
  serializes calls the way the Swift `actor` does; `AbortController`
  replaces `TurnControl`.
- **AppKit / UIKit**: Same answer as the SwiftUI bullet — the coordinator
  is plain `Foundation` logic with no UI framework tie. Both an AppKit and
  a UIKit host consume it through the same `Backend` protocol and the same
  `inboundEvents` stream; nothing in `PersonaChatCoordinator.swift` differs
  between the two.
- **WinUI 3**: Implement the coordinator as a class registered as a
  singleton or scoped service, using `System.Net.Http.HttpClient` for both
  POSTs. Read the SSE body via
  `HttpResponseMessage.Content.ReadAsStreamAsync()` wrapped in a
  `StreamReader`, buffering into blocks the same way `SSEParser` does — a
  hand-rolled block accumulator, since `HttpClient` has no built-in SSE
  support. Serialize and deserialize with `System.Text.Json`
  (`JsonSerializer.Serialize<SendMessageBody>` /
  `JsonSerializer.Deserialize<TokenPayload>`, mirroring the
  encode/decode-with-fallback pattern). Replace `AsyncStream<InboundEvent>`
  with a `System.Threading.Channels.Channel<InboundEvent>`, exposed to
  WinUI as an `IAsyncEnumerable<InboundEvent>` via
  `ChannelReader.ReadAllAsync()` so a page can `await foreach` it on the UI
  thread. Replace the actor's single-writer serialization with a
  `SemaphoreSlim(1, 1)` guarding `conversationID` and `openInvocations`,
  since C# has no actor-isolation model; replace `TurnControl`'s
  `NSLock` + `Task` pair with a `CancellationTokenSource` field, cancelled
  synchronously from a `Destroy()` method. `Windows.Storage` has no role
  here at all — like the Swift source, the port MUST persist nothing to
  disk. `ObservableCollection` and `INotifyPropertyChanged` belong to the
  *consuming* chat view model, not the coordinator itself, exactly as
  `ObservableChatViewModel` — not `PersonaChatCoordinator` — owns
  presentation state on Apple.

