
- **SwiftUI**: Source is `Core/Partner/PartnerStepTemplate.swift`, a caseless `enum` importing only `Foundation`; it uses `NSRegularExpression` with a raw-string pattern and `NSString` ranges (UTF-16 offsets). Nothing is UI-specific.
- **Compose**: Top-level functions on `String` using a `Regex` of an escaped brace, one or more word characters in a capture group and an escaped brace, with `Regex.replace` and a lambda, which is one pass for free; Kotlin's word class is ASCII by default.
- **React/Web**: `String.prototype.replace` with a global regular expression and a replacer function is one pass; look the key up with `Object.hasOwn` rather than `in`, so keys such as `constructor` are not found on the prototype. The quoting is for a POSIX or zsh shell run by Node.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic.
- **WinUI 3**: A static class using `Regex.Replace` with a `MatchEvaluator` that returns `values[key]` when `TryGetValue` succeeds and `match.Value` otherwise; the evaluator form is one pass. .NET's word class matches Unicode letters unless `RegexOptions.ECMAScript` is given, so pin the character class to match the Swift one you are porting. `shellQuoted` targets zsh and POSIX shells; a Windows terminal step run by `cmd.exe` or PowerShell needs its own quoting rule, which this source does not define.

