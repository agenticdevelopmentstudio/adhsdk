
- **quote-wraps-in-single-quotes**: `quote(word)` MUST return the word wrapped in one leading and one trailing single quote, including when the word is plain or empty.
- **quote-escapes-single-quote**: `quote(word)` MUST write each embedded single quote as the five characters `'"'"'` (close the quote, a double-quoted single quote, reopen the quote).
- **quote-replaces-literally**: `quote(word)` MUST escape every U+0027 code point, including one followed by a combining mark (U+0301).
- **quote-preserves-other-characters**: `quote(word)` MUST leave every character other than the single quote unchanged inside the quotes, including spaces, newlines and the combining mark itself.
- **plain-word-unchanged**: `quoteIfNeeded(word)` MUST return the word as is when it is non-empty and every Unicode scalar is one of `A-Z`, `a-z`, `0-9`, `_`, `@`, `%`, `+`, `=`, `:`, `,`, `.`, `/` or `-`. The class is tested per Unicode scalar against these ASCII characters, so a non-ASCII letter such as `é` is never plain.
- **empty-word-quoted**: `quoteIfNeeded("")` MUST return `''`, because an empty string is not in the plain class.
- **non-plain-word-quoted**: `quoteIfNeeded(word)` MUST return `quote(word)` when the word holds any scalar outside the plain class, including a space, a single quote and a non-ASCII letter.
- **command-line-joins-with-space**: `commandLine(words)` MUST return each word passed through `quoteIfNeeded(_:)`, joined by a single space, in the order given.
- **command-line-round-trips**: `commandLine(words)` MUST produce a string that a POSIX shell splits back into exactly the given words, each reaching the command as one argument, for every word that is not in command position (the first word). A first word in assignment form (`FOO=bar`) or a reserved word (`if`) is read by the shell as an assignment or keyword; see the edge cases.
- **pure-functions**: Each function MUST depend only on its arguments, MUST NOT read the environment or a file, and MUST NOT run a process.
- **no-failure-path**: Each function MUST return a string for every input and MUST NOT throw.

