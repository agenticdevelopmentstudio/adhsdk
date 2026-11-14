
- **Theme id with no adjustment**: MUST be returned unchanged. This covers every `webPorted` theme except Fishlamp, and a theme with an id the switch has never seen.
- **Empty `webPorted`**: `webPortedNative` is then empty and `all` is the hand-authored set alone; the map has no precondition on the list's length.
- **Fishlamp already carrying a `card`, `selectionEdge` or `project` value**: the adjustment MUST overwrite the `card` and `selectionEdge` keys and replace `project`; it does not merge with a prior `ThemeProjectOptions`.
- **Fishlamp `roleOverrides` missing the other keys**: the adjustment MUST still succeed, because it assigns through a dictionary subscript, which creates the entries.
- **Generator re-run**: regenerating `BuiltInThemes+Web.swift` MUST NOT remove the adjustments, because they live in this file and are applied after the generated list is read.
- **Generated Fishlamp renamed or removed**: the case compares against `fishlamp.id` read from the generated constant rather than a literal, so a changed id is followed automatically; a renamed or removed `fishlamp` constant stops the file compiling, which is the signal.
- **Malformed hex literal**: not reachable at runtime with the current literals, since `RGBAColor(hexString:)` is force-unwrapped. A mistyped literal in a future edit would trap at first access of `webPortedNative`, and thus of `BuiltInThemes.all`.
- **Concurrent access**: `webPortedNative` is a `static let` and initialises exactly once under the language runtime's guarantee; `nativeAdjusted` is pure and may be called from any thread.
- **Error states, offline and cancellation**: not applicable — the code does no I/O, awaits nothing and cannot throw.

