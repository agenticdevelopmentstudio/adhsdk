
Not applicable: the only user-facing strings the source produces are the
`CustomStringConvertible`/`Error` diagnostic messages (`"bad hex colour:
\(h)"`, `"unknown ease: \(name)"`) used for developer-facing error
descriptions, not localized UI text; nothing in `Color.swift`, `Ease.swift`,
`Mat.swift`, `Prng.swift`, `color.ts`, `ease.ts`, `mat.ts`, or `prng.ts`
loads a string table or locale.

