
- **Empty or missing input**: a knob never pushed MUST read as its `SummaryDefaults` value; a blank prompt (empty or whitespace only) MUST read as the default prompt, because `SummaryPrefs.prompt` treats it as "never configured" and an empty system prompt would turn a titling model into a chatbot.
- **Boundary values**: `clamp` MUST return the bound itself for a value equal to either bound, and `characterCap(maxWords:)` MUST stay at 80 for every `maxWords` up to 8.
- **Out-of-range input**: a value below or above its range MUST clamp to the nearest bound, never be rejected; `Int.max` clamps to the upper bound without overflow because `clamp` only compares.
- **Unparseable stored value**: a stored number that is not an integer MUST fall back to the default, not to a bound; the clamp is not reached. The parse step is in `RawSetting`, outside this file.
- **Prompt without the placeholder**: a prompt that drops `{maxWords}` MUST be sent verbatim; the reply is still trimmed to the cap.
- **Purge threshold drift**: a purge threshold below `characterCap(maxWords:)` would wipe titles just written and re-queue them forever; the purge MUST take its number from this function. `clearOverlongSummaries` (in `SessionRecords`) defaults its `maxCharacters` to the cap at the default max words plus 10 and also blanks any summary containing a newline; its doc comment tells a caller to pass `SummaryDefaults.characterCap(maxWords:)` for the configured limit, and no caller in the repository passes one.
- **Inverted or empty range**: `clamp` does not check the range it is given; the six ranges in this file are fixed and valid, and a caller passing another range owns it.
- **Concurrent access**: every member is an immutable `static let` or a pure function, so concurrent reads are safe with no ordering rule.
- **Error and offline states**: this code makes no network, file or database call and has no error path; a failed settings read is `SummaryPrefs`'s fallback to the default.

