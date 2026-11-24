
- **SwiftUI**: Model the draft with an `@Observable` (or `ObservableObject`)
  editor type holding `draft`/`baseline` and computing `dirty` with an
  `Equatable` record type (Swift's structural `==` on a `struct` gives the
  array/object-content comparison `useDirtyDraft` hand-rolls in TypeScript
  for free). Field descriptors become an enum or protocol-witness list
  (`FieldDescriptor<Value, Context>` as a generic `struct`); layout coverage
  can be checked at compile time with a `CaseIterable` key enum rather than
  TypeScript's mapped-type trick. The repair pass and `EditingScope` rollup
  (an `@Environment`-injected parent reporter) both port directly; the
  navigation guard maps to `.interactiveDismissDisabled` plus a
  confirmation `.alert`.
- **Compose**: A `ViewModel` holding `MutableStateFlow<Draft<T>>` plays the
  role of `useDirtyDraft`; `derivedStateOf`/`combine` compute `dirty` and
  `canSave`. Field descriptors are sealed classes or data classes per
  `ControlKind`; section coverage is best checked with a lint rule or a
  `CoveredKeys`-style compile-time helper generated from a `sealed interface`
  of field keys, since Kotlin's type system cannot replicate the TS
  literal-tuple inference exactly. Nesting/rollup maps to
  `CompositionLocal` for the scope and Jetpack Navigation's
  `BackHandler`/predictive-back APIs for the guard.
  `NavigationEventDispatcher` or the two-argument `PredictiveBackHandler`
  covers the confirm-before-leaving prompt.
- **React/Web**: This is the source. `container.tsx` is the container;
  `controls.tsx` holds the (unexported) bound primitives; `descriptors.ts`
  and `sections.ts` are the declarative, framework-agnostic halves also
  re-exported from `server.ts` for Server Components; `repair.ts` and
  `validation.ts` are pure functions with their own unit tests; `scope.tsx`
  is the nesting/rollup Context; `host.tsx` is the dependency-injection
  point for the platform's `UnsavedChangesGuard`/`AlertModal`. Compile-time
  enforcement (generics, `SectionsCheck`, `@ts-expect-error` tests checked
  via `tsc --noEmit`) is specific to this platform's type system and has no
  literal equivalent elsewhere.
- **AppKit / UIKit**: There is no direct visual analogue since this is a
  data layer, not a control; a UIKit/AppKit port would center the same
  `EditingController` object (an `NSObject`/plain class, not a view)
  holding `draft`/`baseline`/`dirty` via KVO or a delegate callback, with
  `NSFormatter`/manual field wiring standing in for `BoundField`. The
  repair pass and navigation guard translate to a modal
  `UIAlertController`/`NSAlert` (mirroring the non-dismissible
  single-button prompt) and `UIViewController`'s
  `isModalInPresentation`/window-close interception, respectively.
- **WinUI 3**: Represent `draft`/`baseline` as two instances of a
  `partial class` implementing `INotifyPropertyChanged`, with `dirty`
  computed by comparing them field-by-field (or via a generated
  `IEquatable<T>` on a C# `record`, which gives structural equality the way
  `useDirtyDraft`'s `sameValue` does for plain objects/arrays). Field-level
  errors surface through `INotifyDataErrorInfo` so bound `TextBox`/
  `ComboBox`/`CheckBox` controls show validation state natively instead of
  through a hand-rolled error prop; `TextBox.MaxLength`/`InputScope` cover
  `placeholder`/`rows`-equivalent options, and a `ComboBox` bound to an
  `ObservableCollection<SelectOption>` needs an explicit "insert the current
  unlisted value as an extra item" step to match
  `select-shows-unlisted-stored-value`, since WinUI's `ComboBox` has no
  built-in equivalent. The repair pass's non-dismissible prompt maps to a
  `ContentDialog` with `CloseButtonText` unset and `IsPrimaryButtonEnabled`
  bound to the "not yet applying" state, `DefaultButton` set so Enter
  confirms, and no `system-close` handling — WinUI's `ContentDialog` does
  not raise Escape as a distinct event the way a web `Escape` keydown does,
  so the equivalent guard is simply omitting the close (`X`) affordance
  that `ContentDialog` would otherwise show. Section/field coverage has no
  compile-time equivalent in C#'s type system (no literal-tuple inference);
  the nearest practical equivalent is a source generator or a unit test
  that walks a `[Field(nameof(...))]`-attributed list against the view
  model's declared sections at build time, rather than the compiler itself
  rejecting the mismatch. The navigation guard maps to `Frame.Navigating`
  (or `NavigationView`'s equivalent) combined with a `ContentDialog`
  confirmation and `Window.Closing` for the app-exit case, rolled up across
  nested edit surfaces via a shared `IEditingScope` service registered per
  `Frame`/`Page` rather than React Context.

