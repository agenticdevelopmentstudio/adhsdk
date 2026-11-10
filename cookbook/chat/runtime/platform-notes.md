
- **React/Web** (source platform): This IS the reference implementation —
  `packages/web/packages/chat/src/runtime/DefaultOrchestrator.ts`,
  `InMemoryPermissionStore.ts`, and `ScriptedBackend.ts`. State lives in plain
  class fields reassigned via immutable copies (`[...this.messages, message]`,
  a fresh `Map`), notification is a `Set<ChatStateObserver>` iterated
  synchronously, and the inbound stream is a native `AsyncIterable`/
  `AsyncIterator` consumed by a `while (!this.stopped)` loop awaiting
  `iterator.next()`.
- **SwiftUI**: Model `Orchestrator` as an `@Observable` (or, on older targets,
  `ObservableObject` with `@Published`) class exposing the same fields; back
  the inbound stream with Swift's native `AsyncStream<InboundEvent>` (the
  direct analog of a JS async iterable) and drive the consumer with a `Task`
  that `for await`s it, cancelling that `Task` in place of `stop()`'s
  `iterator.return()`. Port `PermissionStore` as a small `actor` (or a
  `@MainActor`-isolated class) wrapping a `Dictionary`, since
  `InMemoryPermissionStore`'s backing `Map` has no synchronization of its own
  in source and Swift's concurrency checker will require an explicit
  isolation choice once the type crosses an `async` boundary.
- **Compose**: Expose the view-model's fields as `mutableStateOf`/
  `SnapshotStateList` properties (or a `StateFlow<ChatViewModel>` for
  Flow-oriented composition) so recomposition tracks the same fields
  `DefaultOrchestrator` reassigns wholesale. Back `Backend.inboundEvents` with
  a Kotlin `Flow<InboundEvent>` and drive the consumer with
  `flow.collect { }` inside a `viewModelScope.launch` coroutine, in place of
  the async `while` loop. Back `PermissionStore` with a `MutableMap` guarded
  by a `Mutex` (or hosted on a single-threaded `CoroutineDispatcher`), since
  nothing in `InMemoryPermissionStore.ts` synchronizes concurrent access
  either.
- **AppKit / UIKit**: No SwiftUI dependency is required — the same
  `Orchestrator`-conforming reference type works as a plain reference type
  whose `ChatStateObserver`s are AppKit/UIKit controllers implementing
  `chatDidUpdate`. Source notifies synchronously and inline, with no thread
  hop of its own, so an AppKit/UIKit host MUST hop to the main queue itself
  before touching views — `DefaultOrchestrator.ts` performs no such hop.
- **WinUI 3**: Model `ChatViewModel`'s mutable array-valued fields
  (`messages`, `participants`, `activeDrafts`, `activeCommands`,
  `readMarkers`, `pendingWidgets`, `typingParticipants`) as
  `ObservableCollection<T>` properties on a class implementing
  `INotifyPropertyChanged`, raising collection-changed/`PropertyChanged`
  events in place of the source's `notify(ChatUpdate)` fan-out to a
  `HashSet<ChatStateObserver>` (a WinUI host would more naturally bind views
  directly to the `ObservableCollection`s than replicate the
  `ChatStateObserver` push model one-for-one, though a thin
  `IObservable<ChatUpdate>`-style event can be layered on top to match call
  sites exactly). Back `Backend.InboundEvents` with `IAsyncEnumerable<InboundEvent>`
  (`System.Text.Json` for any wire encoding, `HttpClient` inside a concrete
  `Backend` for a networked implementation) and drive the consumer with
  `await foreach (var evt in backend.InboundEvents.WithCancellation(cts.Token))`
  inside a `Task.Run`, cancelling a `CancellationTokenSource` from `Stop()` in
  place of `iterator.return()`. Port `InMemoryPermissionStore` as a class
  wrapping a `Dictionary<string, PermissionDecision>` guarded by a `lock` (or
  a `ConcurrentDictionary`) — .NET gives no free single-threaded guarantee the
  way the JS runtime does, so the "no internal synchronization" characteristic
  documented in Design Decisions MUST become an explicit lock on this
  platform rather than staying implicit.

