
- **SwiftUI**: Not used; the enum has no view layer.
- **Compose**: Port as a Kotlin `sealed interface ParseResult` with `data class Event`, `data class Skip`, and `object LostEvent` and `object Unparseable`; parse with `kotlinx.serialization.json.Json.parseToJsonElement` inside `runCatching`, since the source's `try?` swallows the decode error.
- **React/Web**: Port as a discriminated union on a `kind` field; `JSON.parse` in `try`/`catch`, then check `typeof` for each field and reject arrays and `null` as non-objects before reading keys.
- **AppKit / UIKit**: `Core/Sessions/ParseResult.swift`, using `JSONSerialization.jsonObject(with:)` cast to `[String: Any]` and `String.trimmingCharacters(in: .whitespacesAndNewlines)`; the rest is Foundation.
- **WinUI 3**: Use an abstract record `ParseResult` with sealed records `Event`, `Skip`, `LostEvent` and `Unparseable` (or a `OneOf`-style union), `string.IsNullOrWhiteSpace` for the empty test, and `System.Text.Json.JsonDocument.Parse` in `try`/`catch (JsonException)`, checking `JsonValueKind.Object` and `JsonValueKind.String` as the source's casts do. Keep the empty-versus-malformed order. `JsonDocument` is disposable: clone `hook_data` and `context` with `JsonElement.Clone()` or convert them to `Dictionary<string, object?>` before it is disposed.

