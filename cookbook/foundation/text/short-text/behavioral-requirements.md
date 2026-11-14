
- **extension-scope**: The component MUST be a public method `shortened(to:)` on `String` that returns a `String`.
- **default-limit**: The `limit` parameter MUST default to 60.
- **fits-unchanged**: When the text's `Character` count is less than or equal to `limit`, the method MUST return the text unchanged.
- **cut-length**: When the text's `Character` count is greater than `limit`, the method MUST return the first `limit - 3` characters followed by the single character `…` (U+2026), so a cut result is `limit - 2` characters long, two under the limit.
- **count-in-characters**: The length and the cut MUST be measured in Swift `Character`s (extended grapheme clusters), not UTF-8 bytes or UTF-16 units, so a cut never splits a character.
- **ellipsis-single**: The ellipsis MUST be the one character `…` and MUST NOT be three full stops.
- **minimum-limit**: A caller MUST pass a `limit` of at least 3 whenever the text may be longer than the limit; the doc comment declares this precondition and the method does not validate it.
- **limit-three**: With a `limit` of exactly 3 and a text longer than 3 characters, the result MUST be the ellipsis alone.
- **pure**: The method MUST have no side effect and MUST NOT mutate the receiver.
- **no-word-boundary**: The cut MUST fall at a character position, not a word boundary, and the method MUST NOT trim trailing whitespace before the ellipsis.
- **single-budget**: Callers that show a one-line message in a width-limited card SHOULD use this method with its default instead of writing the number 60 again, which is the reason the source gives for the helper's existence.
- **dependencies**: The component MUST depend only on Foundation.

