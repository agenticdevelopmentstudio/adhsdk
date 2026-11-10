
- **Free text with no match.** The typed text remains the value; the popup shows the empty message. The input is not forced to a suggestion.
- **Duplicate suggestion strings.** Each row is keyed by its string value (`key={item}`), so callers MUST de-duplicate `items` before passing them in — duplicate strings would share a React key and produce undefined rendering behavior.
- **Long lists.** The popup scrolls within `--available-height`; the active row scrolls into view via the primitive.
- **Picking equals current text.** Re-picking the row already equal to the value is a no-op edit.
- **Opening method.** In a real browser the popup opens as the user types; programmatic tests open it with an ArrowDown keydown (the first ArrowDown opens, the next highlights).

