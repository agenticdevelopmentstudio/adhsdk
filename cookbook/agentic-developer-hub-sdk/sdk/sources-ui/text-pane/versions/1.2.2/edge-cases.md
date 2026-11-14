
- **Empty text**: Reading `text` when the pane is empty returns an empty string (never nil). Setting `text = ""` clears all content without firing `onTextChange`.
- **Null/nil text**: The API surface does not expose nil values. `UITextView.text` and `NSTextView.string` are always safe-unwrapped in the implementation, so read operations never return null.
- **Rapid successive edits**: User performs multiple edits in quick succession. Each edit fires `onTextChange` independently; no debouncing or throttling is performed. The caller is responsible for debouncing if needed.
- **Very large text**: Pane contains megabytes of text. The implementation uses native text views without pagination or virtual scrolling, so rendering performance depends on platform capabilities. No explicit size limits are enforced.
- **Programmatic text set while user is editing**: Caller sets `text` programmatically while the user is actively editing. The text immediately updates without firing `onTextChange`, potentially discarding in-flight edits. This is the expected behavior per the re-entrancy safeguard design.
- **Theme change mid-edit**: `applyTheme()` is called while text is being edited. Colors and font update immediately; the text view remains editable with no interruption.
- **Focus request off-screen**: User calls `focus()` on a pane that is not in the visible window hierarchy. On iOS, `becomeFirstResponder()` returns `false` when the view has no window — UIKit requires the view to be attached to a window to become first responder, so no focus change occurs. On macOS, `window?.makeFirstResponder(textView)` returns `false` if `window` is `nil`, with the same result.
- **Read-only to editable transition during selection**: User selects text, then the pane transitions to read-only. Selection remains visible. Transitioning back to editable preserves the selection. User can type to replace it.
- **Attributed text with no attributes**: Read `attributedText` when `text` is plain with no styling applied. Returns an `NSAttributedString` with no attributes attached to the characters.

