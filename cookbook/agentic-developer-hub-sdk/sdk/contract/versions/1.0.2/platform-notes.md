
- **SwiftUI**: Sources live under
  `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/{Attachments,Backend,Chat,Commands,Configuration,Hooks,Media,Messages,Orchestrator,Participants,Permissions}/`.
  `ChatViewModel` is `@MainActor, AnyObject, Sendable`; the two given actor
  conformers (`ScriptedBackend`, and `PersonaChatCoordinator` referenced from
  its doc comments) hold `inboundEvents`/its continuation as `nonisolated
  let`, so a `SwiftUI` view can start consuming the stream without waiting on
  the actor.
- **Compose**: Translate `AsyncStream<InboundEvent>` to a `Flow<InboundEvent>`;
  translate the closed-set enums (`InboundEvent`, `ChatUpdate`,
  `MessageDeliveryStatus`, `AttachmentSource`, `AttachmentPresentation`,
  `ParticipantKind`, `ParticipantConversationState`, `CommandInvoker`,
  `PermissionDecision`, `GatingPoint`, `ObservingPoint`, `HookDecision`) to
  Kotlin `sealed class`/`sealed interface` hierarchies rather than plain
  `enum class`, since several carry payloads; represent `ChatViewModel` as a
  `ViewModel` exposing `StateFlow` properties in place of the
  observer-registration pattern; give a `ScriptedBackend` port its own
  `Mutex`-guarded class, since Kotlin has no built-in actor equivalent.
- **React/Web**: Sources live under
  `packages/web/packages/chat/src/contract/{attachments,backend,chat,commands,configuration,hooks,media,messages,orchestrator,participants,permissions}/`.
  Closed sets are discriminated unions matched on a `kind` field rather than
  enums; collections are typed `ReadonlyArray`/readonly interfaces to signal
  the same immutability `let`/`Sendable` signal on apple; the contract types
  themselves import no React and carry no framework coupling.
- **AppKit/UIKit**: The same Swift package serves both; `ChatViewModel`'s
  `@MainActor` isolation matches AppKit/UIKit's main-thread-only view and
  control update requirement directly, so no additional dispatching is needed
  at the view layer beyond what `@MainActor` already provides.
- **WinUI 3**: `AsyncStream`/async-iterable becomes a
  `System.Threading.Channels.Channel<InboundEvent>` exposed as
  `IAsyncEnumerable<InboundEvent>` via `ChannelReader.ReadAllAsync()`, with a
  single orchestrator consuming it and fanning out through property-change
  notifications. Payload-carrying closed sets (`InboundEvent`, `HookDecision`,
  `MessageDeliveryStatus`, `AttachmentSource`) become an `abstract record` base
  with one `sealed record` per case, pattern-matched with a C# `switch`
  expression, rather than a single enum with nullable fields for every case.
  `Message`/`Participant`/`Attachment`-shaped protocols become C# interfaces
  or `record` types; `ChatViewModel`/`Orchestrator` become an interface
  implementing `INotifyPropertyChanged` for XAML binding, backing
  `messages`/`participants`/`activeDrafts`/`pendingWidgets`/`pendingPermissions`
  with `ObservableCollection<T>` in place of the update-then-re-read pattern
  `ChatUpdate` uses. `Backend.send`/`setLocalTyping`/`submitWidgetResponse`
  become `Task`-returning `async` methods, with `HttpClient` for a networked
  conformer's transport and `System.Text.Json` for the opaque
  `payloadJSON`/`argumentSchema`/`resultJSON` strings. A `ScriptedBackend` port
  replaces `AsyncStream.Continuation` with a `Channel<InboundEvent>` writer and
  `Task.sleep(for:)` with `Task.Delay`, chaining turns with awaited tasks the
  way `replayChain` does. `Windows.Storage` has no role at this layer: the
  contract performs no persistence of its own (see Privacy).

