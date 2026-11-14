
- **placeholder-syntax**: A placeholder MUST be an opening brace, one or more word characters (the regular-expression word class, which in Swift's `NSRegularExpression` includes Unicode letters and numerals, plus underscore) and a closing brace; `{}` and `{two words}` are not placeholders.
- **fill-known**: `fill(_:values:)` on a command MUST replace each placeholder whose key has a value with that value.
- **unknown-stays**: A placeholder whose key has no value MUST stay in the output exactly as written.
- **one-pass**: Substitution MUST be one pass over the original command; a value MUST NOT be scanned for placeholders, so a value containing `{key}` appears as written.
- **text-between-preserved**: All text outside replaced placeholders MUST be copied unchanged.
- **terminal-quoting**: `fill(_:values:)` on steps MUST quote every value with `shellQuoted` before filling a step whose environment is `terminal`.
- **claude-unquoted**: The same function MUST fill a step whose environment is `claude` with the values as written.
- **steps-keep-fields**: The step function MUST return one step per input step, in order, changing only `command`; `name`, `environment` and `condition` MUST be unchanged.
- **plain-word-unquoted**: `shellQuoted` MUST return a value as written when it is not empty and every character is an ASCII letter, an ASCII numeral, or one of `_ - . / : @ + ,`.
- **otherwise-single-quoted**: `shellQuoted` MUST otherwise return the value wrapped in single quotes, with each single quote in the value written as the four characters quote, backslash, quote, quote.
- **empty-is-quoted**: `shellQuoted` MUST return two single quotes for an empty value, so it stays one word.
- **no-equals-no-tilde**: `shellQuoted` MUST quote a value containing `=` or `~`; the source comment says a leading `=` is zsh's command-path expansion.

