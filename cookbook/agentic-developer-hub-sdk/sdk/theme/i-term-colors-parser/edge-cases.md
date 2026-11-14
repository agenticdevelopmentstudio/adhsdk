
- **Empty data** (MUST): zero-length `Data` fails in `PropertyListSerialization` and the Foundation error propagates.
- **Malformed or non-plist bytes** (MUST): the Foundation parse error propagates; it is not an `ITermColorsParseError`.
- **Non-dictionary root**: an array, string or number root throws `notADictionary` (see `top-level-must-be-dictionary`).
- **Required key present but not a dictionary** (MUST): a value of the wrong type under a color key is treated as absent and throws `missingColor` with that key.
- **Component of the wrong type**: see `component-type-strict`. A plist `integer` (for example `1`) bridges to `Double` and is accepted.
- **Out-of-range components**: see `channel-clamping`.
- **Boundary luminance**: see `luminance-boundary-light`.
- **Translucent background**: see `appearance-ignores-alpha`.
- **Foreground differs from background only by alpha**: see `foreground-alpha-distinct`.
- **Malformed optional color**: see `cursor-fallback` and `selection-fallback`. The malformed value is discarded without a signal.
- **Partial files** (MUST): a file with cursor and selection omitted still parses.
- **Extra or unknown keys**: see `extra-keys-ignored`.
- **Unreadable file in the URL overload** (MUST): the error from `Data(contentsOf:)` propagates.
- **Concurrent access**: the parser holds no shared mutable state, so concurrent calls cannot interfere.
- **Cancellation and timeout**: not applicable; the parser is synchronous, has no timeout and no cancellation point.
- **Offline or disconnected state**: not applicable; the URL overload reads a file URL and the parser makes no network request of its own.
- **Large input**: nothing in the source bounds the input size; the whole file is read into memory.

