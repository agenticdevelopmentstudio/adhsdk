
- **Swift**: A `Sendable`, `Hashable` value type in the Foundation-only Core
  framework, with a static `parse(_:)` returning an optional document and
  `resolved(_:)` taking a dictionary from conflict index to choice. Lines
  are split with `components(separatedBy: "\n")`, which works on UTF-16
  code units, so a `"\r\n"` line keeps its carriage return. Only the
  trailing-newline check looks at Unicode scalars, because `"\r\n"` is a
  single `Character` in Swift and a character-level suffix check would miss
  it.
- **Other platforms**: Split on the line-feed byte or code point, never on a
  platform line-ending abstraction that would swallow the carriage return.
