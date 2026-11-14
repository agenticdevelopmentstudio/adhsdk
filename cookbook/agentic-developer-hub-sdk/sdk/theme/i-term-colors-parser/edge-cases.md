
- **Empty data** (MUST): zero-length `Data` fails in `PropertyListSerialization` and the Foundation error propagates.
- **Malformed or non-plist bytes** (MUST): the Foundation parse error propagates; it is not an `ITermColorsParseError`.
- **Non-dictionary root** (MUST): an array, string or number root throws `notADictionary`.
- **Required key present but not a dictionary** (MUST): a value of the wrong type under a color key is treated as absent and throws `missingColor` with that key.
- **Component of the wrong type** (MUST): a string or other value that does not bridge to `Double` under a component key throws `missingComponent`. A plist `integer` (for example `1`) bridges to `Double` and is accepted.
- **Out-of-range components** (MUST): values below 0 or above 1 clamp to 0 and 1, per the `RGBAColor` initializer's doc comment.
- **Boundary luminance** (MUST): a background with relative luminance exactly 0.5 is `.light`, because `isDark` is a strict less-than.
- **Translucent background** (MUST): alpha does not enter the dark/light inference, because `relativeLuminance` reads only the channels.
- **Foreground differs from background only by alpha** (MUST): the colors compare unequal, so the theme is accepted.
- **Malformed optional color** (MUST): a `Cursor Color` or `Selection Color` that exists but is malformed is treated like an absent one and falls back silently. This is deliberate, per the source comment that cursor and selection are "common but not universal", and the malformed value is discarded without a signal.
- **Partial files** (MUST): a file with cursor and selection omitted still parses.
- **Extra or unknown keys** (MUST): ignored.
- **Unreadable file in the URL overload** (MUST): the error from `Data(contentsOf:)` propagates.
- **Concurrent access**: the parser holds no shared mutable state, so concurrent calls cannot interfere.
- **Cancellation and timeout**: not applicable; the parser is synchronous, has no timeout and no cancellation point.
- **Offline or disconnected state**: not applicable; the URL overload reads a file URL and the parser makes no network request of its own.
- **Large input**: nothing in the source bounds the input size; the whole file is read into memory.

