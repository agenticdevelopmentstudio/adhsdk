
- **SwiftUI**: Not used; the enum has no view layer, though Settings views iterate `allCases` to drive hook install and uninstall.
- **Compose**: Port as a Kotlin `enum class` with a `rawValue` property, and `companion object` sets as `Set<String>`; `Map<String, Any?>` for `hookData`, read with `as? String` safe casts.
- **React/Web**: Port as a string-literal union plus a frozen `Set<string>` per constant; read `hookData` as `Record<string, unknown>` and test `typeof value === "string"`; build `tableName` with a replace on uppercase letters that skips index 0.
- **AppKit / UIKit**: `Core/Sessions/HookEventType.swift`, a plain Foundation enum with no AppKit or UIKit use; `tableName` iterates `Character.isUppercase`, which is Unicode-aware.
- **WinUI 3**: Use a C# `enum` with a `[JsonStringEnumMemberName]` or a static `Dictionary<HookEventType, string>` for the raw values (a C# enum has no raw strings), `Enum.GetValues<HookEventType>()` for `allCases`, `HashSet<string>` constants (`FrozenSet<string>` on .NET 8) and `IReadOnlyDictionary<string, object?>` or `JsonElement` for `hookData`, checking `JsonValueKind.String` instead of `as? String`. `tableName` maps to `char.IsUpper` over `string`; return `int` from the clock as the source does. All of it is pure, so `static` methods in a `static class` suffice.

