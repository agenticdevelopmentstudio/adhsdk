
| Option | Web (`TypingIndicatorProps`) | macOS (`ThinkingIndicatorConfiguration`) | iOS (`MobileThinkingIndicatorConfiguration`) | Description |
|--------|------|------|------|-------------|
| Turn active | `isTyping: boolean` (required) | `update(status: ChatStatus?)` method parameter | `update(status: ChatStatus?)` method parameter | Whether a turn is currently in flight. Drives phase transitions. |
| Status words | `labels?: readonly StatusWordPair[]` (default: none) | `words: [ChatStatusWordPair]` (default `[]`) | `words: [ChatStatusWordPair]` (default `[]`) | Vocabulary for status words in present and past tense. Empty means the three-dot fallback (see **handle-empty-word-bag**). |
| Frame glyphs | `frames?: readonly string[]` (default: braille spinner) | `frames: [String]` (default: braille spinner) | `frames: [String]` (default: braille spinner) | Frame characters for the rotating glyph animation. |
| Done glyph | `doneGlyph?: string` (default `'✱'`) | `doneGlyph: String` (default `'✱'`) | `doneGlyph: String` (default `'✱'`) | Character displayed in the settled "done" line. |
| Frame interval | `frameMs?: number` (default `260`) | `frameInterval: Duration` (default `.milliseconds(260)`) | `frameInterval: Duration` (default `.milliseconds(260)`) | Interval between glyph animation frames. |
| Word interval | `labelMs?: number` (default `1800`) | `wordInterval: Duration` (default `.milliseconds(1800)`) | `wordInterval: Duration` (default `.milliseconds(1800)`) | Interval between status word rotations. |
| Colorful mode | `colorful?: boolean` (default `false`) | `colorful: Bool` (default `false`) | Not supported | When true, flash random non-green hues while thinking or uttering. |
| Tint | `tint?: StatusTintSpec` (default `undefined`) | `tint: ThinkingTint?` (default `nil`) | Not supported | Optional color and apply scope (icons/words/both) for the active line. |
| Idle phrase | `idlePhrase?: string` (default `undefined`) | `idlePhrase: String?` (default `nil`) | Not supported | Text to display before the first turn begins (settles to grey). Yields on first turn. |
| Utterance | `utterance?: string \| null` (default `undefined`) | `say(_ utterance: String)` / `clearUtterance()` methods | `say(_ utterance: String)` / `clearUtterance()` methods | Transient utterance text that overrides phase content, including the settled line. On web it persists until the caller clears it. On macOS/iOS it is dropped early by the shared phase machine on a turn transition or a fresh status; see **Turn transitions during utterance**. |

