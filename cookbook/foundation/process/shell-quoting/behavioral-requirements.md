
- **quote-wraps-in-single-quotes**: `quote(word)` MUST return the word wrapped in one leading and one trailing single quote, including when the word is plain or empty.
- **quote-escapes-single-quote**: `quote(word)` MUST write each embedded single quote as the five characters `'"'"'` (close the quote, a double-quoted single quote, reopen the quote).
- **quote-replaces-literally**: `quote(word)` MUST find embedded single quotes by literal code-point comparison, not by grapheme comparison, so a single quote followed by a combining mark (U+0301) is still escaped. The source comment records that the default grapheme comparison would leave it unescaped and break the quoting.
- **quote-preserves-other-characters**: `quote(word)` MUST leave every character other than the single quote unchanged inside the quotes, including spaces, newlines and the combining mark itself.
- **plain-word-unchanged**: `quoteIfNeeded(word)` MUST return the word as is when it is non-empty and every Unicode scalar is one of `A-Z`, `a-z`, `0-9`, `_`, `@`, `%`, `+`, `=`, `:`, `,`, `.`, `/` or `-`.
- **empty-word-quoted**: `quoteIfNeeded("")` MUST return `''`, because an empty string is not in the plain class.
- **non-plain-word-quoted**: `quoteIfNeeded(word)` MUST return `quote(word)` when the word is empty or holds any scalar outside the plain class, including a space, a single quote and a non-ASCII letter.
- **plain-set-is-ascii-only**: The plain class MUST be tested per Unicode scalar against the listed ASCII characters, so a non-ASCII letter such as `é` is never plain.
- **command-line-joins-with-space**: `commandLine(words)` MUST return each word passed through `quoteIfNeeded(_:)`, joined by a single space, in the order given.
- **command-line-round-trips**: `commandLine(words)` MUST produce a string that a POSIX shell splits back into exactly the given words.
- **pure-functions**: Each function MUST depend only on its arguments, MUST NOT read the environment or a file, and MUST NOT run a process.
- **no-failure-path**: Each function MUST return a string for every input and MUST NOT throw.

