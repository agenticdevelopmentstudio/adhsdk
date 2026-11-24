
- **React/Web (reference implementation)**: as described throughout —
  `useEffect`/`useLayoutEffect`, `useRef`-held mutable closures,
  `requestAnimationFrame`-coalesced measurement, `ResizeObserver`/
  `MutationObserver`, native `Image`, `setTimeout`/`setInterval`, and DOM
  `RefObject`s as the entire configuration surface for the DOM-touching
  hooks.
- **SwiftUI (Apple)**: `useChatSession` maps to an `@Observable` (or
  `ObservableObject`) coordinator exposing `messages`/`isTyping` as
  published properties and `sendMessage`/`say`/`sayStream` as `async`
  methods run on `Task`s that are stored and explicitly cancelled — rather
  than landed via a pending closure `Set` — when the owning view
  disappears. Caret/gaze/scroll hooks become `GeometryReader`/
  `PreferenceKey`-driven measurements, or drop down to `UIViewRepresentable`/
  `NSViewRepresentable` bridges so `UITextView`/`NSTextView` caret-rect APIs
  can replace the hidden-mirror-`<span>` measurement entirely.
- **Jetpack Compose (Android)**: `useChatSession` becomes a `ViewModel`
  exposing `StateFlow`/`mutableStateOf`; `say`/`sayStream` become `suspend`
  functions launched in `viewModelScope`, landed from `onCleared()` instead
  of an unmount effect. Caret/scroll geometry hooks map to
  `Modifier.onGloballyPositioned`/`LayoutCoordinates` and
  `BringIntoViewRequester`; timers map to `delay()` inside a coroutine
  rather than `setTimeout`/`setInterval`.
- **AppKit/UIKit (imperative Apple)**: the transport hook becomes a plain
  coordinator object exposing KVO-observable properties or a delegate
  callback. DOM-ref-based hooks (caret, gaze, sizing, scroll, focus reclaim)
  map onto `NSTextView`/`UITextView` caret and selection APIs,
  `NSTrackingArea`/hover gesture recognizers for gaze, and Auto Layout
  constraint changes plus `CATransaction` animation blocks in place of the
  CSS-transition-driven `pc-anim` class.
- **WinUI 3 (Windows)**: this is the reason this recipe exists — there is
  no existing Windows port. `useChatSession`'s transport/orchestrator glue
  maps to a coordinator class implementing `INotifyPropertyChanged`, backed
  by an `ObservableCollection<ChatMessage>` for `messages`, with
  `sendMessage`/`say`/`sayStream` as `async Task` methods that issue
  requests through `HttpClient` and decode SSE/JSON payloads with
  `System.Text.Json`; the pending-lines-landed-on-teardown pattern
  (**session-say-landing-on-teardown**) maps to cancelling and awaiting
  outstanding `Task`s from the control's `Unloaded` handler rather than
  firing-and-forgetting them. `useConnectRitual`'s cadence and give-up
  timers (**ritual-status-stepping**, **ritual-engage-on-pointer**) map to
  `DispatcherQueueTimer`, gated by an `alive`-equivalent boolean field
  re-armed in the control's `Loaded` handler — WinUI's nearest analog of a
  React Strict Mode remount is a control being unloaded and reloaded inside
  a navigation frame's page cache. `caretMetrics`/`useCaretTracker`/
  `useBlockCursor`/`useCaretGaze` translate directly to
  `TextBox.SelectionStart` and `TextBox.GetRectFromCharacterIndex` — a
  native replacement for the hidden-mirror-`<span>` measurement — polled or
  hooked via `TextBox.SelectionChanged`/`GotFocus`/`LostFocus`, with a
  `DispatcherQueueTimer` standing in for `requestAnimationFrame` coalescing.
  `useMouseGaze`/`usePersonaGaze` map to `UIElement.PointerMoved`, and
  `useChatSizing`'s `ResizeObserver`-driven cap becomes a `SizeChanged`
  handler on the relevant `FrameworkElement`s feeding an
  `INotifyPropertyChanged`-bound `MaxHeight`. `useScrollToBottom` maps to
  `ScrollViewer.ChangeView`, triggered from the same
  `ObservableCollection<ChatMessage>.CollectionChanged` event that stands in
  for the `MutationObserver`. Any persistence a caller layers on top of
  these hooks belongs to `Windows.Storage.ApplicationData` — none of these
  hooks themselves persist anything.

