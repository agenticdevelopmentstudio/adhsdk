
- **SwiftUI**: this is the Apple source platform. The engine is pure
  Foundation model code (`Codable` structs/enums decoded with
  `JSONDecoder`) with no `import SwiftUI` anywhere in `Loader.swift` or
  `Types.swift`; a SwiftUI host consumes the returned `CharacterConfig` as
  plain data, never observing it as `@Published`/`@Observable` state, since
  the loader itself never mutates it after return.
- **AppKit/UIKit**: no distinction from the SwiftUI note above — the same
  `CharacterConfig.load(_:)` and `RawFiles.read(fromDirectory:)` serve both
  UI hosts identically, since neither imports any UI framework.
- **React/Web**: this is the other source platform.
  `packages/web/packages/avatar-engine/src/config/load.ts` and `types.ts`
  mirror the Apple types with TypeScript interfaces and perform the
  identical validation phases; the one Apple-only entry point is
  `RawFiles.read(fromDirectory:)`, since the web build receives its six
  sources as already-parsed JSON module imports rather than reading files
  itself.
- **Compose (Kotlin/Android, port target)**: a Kotlin port would model the
  six file shapes as `kotlinx.serialization`-annotated data classes/sealed
  classes in place of `Codable` structs/TS interfaces, decode with
  `Json.decodeFromString`, and implement `load` as an ordinary synchronous
  function — no coroutine or `Flow` is warranted, since the reference
  loader on both platforms is synchronous and side-effect-free.
- **WinUI 3 (.NET, port target)**: a .NET port would model the six file
  shapes as C# records deserialized with `System.Text.Json`, use
  `Windows.Storage.StorageFolder.GetFileAsync`/`File.ReadAllBytesAsync` in
  place of `RawFiles.read(fromDirectory:)`, and raise a dedicated exception
  type (mirroring `ConfigError`) whose message carries the same file/key
  attribution the Apple and web messages do. `ObservableCollection`/
  `INotifyPropertyChanged` do not apply: the returned config is an
  immutable value produced once per call, never observed for later
  in-place changes.

