
`ITermColorsParser` is a stateless, caseless `enum` that turns the bytes of an iTerm2 `.itermcolors` file into a `ColorTheme`. An `.itermcolors` file is a property list (XML or binary) whose top-level dictionary maps color keys (`Ansi 0 Color` through `Ansi 15 Color`, `Foreground Color`, `Background Color`, `Cursor Color`, `Selection Color`) to dictionaries of `Red Component`, `Green Component`, `Blue Component` and `Alpha Component` reals in 0 to 1. The parser uses Foundation's `PropertyListSerialization` and has no third-party dependency.

Use it to import a terminal color scheme as an app theme. The parser is strict about the foreground, background and 16 ANSI colors, and lenient about cursor, selection and alpha. It does no I/O of its own except the URL overload, which reads the file with `Data(contentsOf:)`.

