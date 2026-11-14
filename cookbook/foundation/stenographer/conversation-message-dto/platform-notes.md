
- **SwiftUI**: Not used; a view model binds to the messages, and a follower view holds `nextAfterId` as its cursor.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; model `agentId` and `nextAfterId` as nullable properties with a default of null so an older payload still decodes, and fold `kind` in one `when` with an else branch of `model`.
- **React/Web**: TypeScript interfaces; `agentId?: string` and `nextAfterId: number | null`; keep ids as numbers (they are Swift `Int`, 64-bit, so confirm the range is within `Number.MAX_SAFE_INTEGER`).
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/ConversationMessageDTO.swift`: `Codable`, `Sendable`, `Equatable` structs whose synthesized `Codable` decodes a missing `agentId` as nil, plus an enum conforming to `LocalizedError`.
- **WinUI 3**: Use C# records with `System.Text.Json` (`long` for the ids, `string?` for `agentId`, `long?` for `nextAfterId`); an `Exception` subclass such as `ConversationRangeException` carrying the id and overriding `Message` to return the same sentence replaces `LocalizedError`; a `switch` expression with a discard arm models `type(forKind:)`; there is no `Sendable`, so make the records immutable (`init`-only properties); a follower page drives an `ObservableCollection` of messages while keeping the last id as its cursor.

