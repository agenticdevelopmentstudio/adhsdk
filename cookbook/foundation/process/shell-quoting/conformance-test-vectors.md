
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| shell-quoting-001 | empty-word-quoted | `quoteIfNeeded("")` | `''` (test: emptyWordIsQuoted). |
| shell-quoting-002 | plain-word-unchanged | `quoteIfNeeded("/usr/local/bin/{{app_name_lower}}-1.2")` | `/usr/local/bin/{{app_name_lower}}-1.2` (test: plainWordIsUnchanged). |
| shell-quoting-003 | quote-escapes-single-quote, non-plain-word-quoted | `quoteIfNeeded("it's")` | `'it'"'"'s'` (test: singleQuoteIsEscapedLikeShlex). |
| shell-quoting-004 | quote-replaces-literally | `quote("a'" + U+0301 + "b")` | `'a'"'"'` + U+0301 + `b'` (test: singleQuoteBeforeCombiningMarkIsEscaped). |
| shell-quoting-005 | non-plain-word-quoted | `quoteIfNeeded("a b")` | `'a b'` (test: spacesAreQuoted). |
| shell-quoting-006 | plain-word-unchanged, non-plain-word-quoted | `quoteIfNeeded("caf" + U+00E9)` | `'caf` + U+00E9 + `'` (test: nonASCIILetterIsQuoted). |
| shell-quoting-007 | quote-wraps-in-single-quotes | `quote("plain")` | `'plain'` (test: quoteAlwaysQuotes). |
| shell-quoting-008 | command-line-joins-with-space, plain-word-unchanged, non-plain-word-quoted | `commandLine(["ls", "-la", "my dir"])` | `ls -la 'my dir'` (test: commandLineQuotesOnlyWordsThatNeedIt). |
| shell-quoting-009 | quote-escapes-single-quote | `quote("'")` | `''"'"''`: the opening quote, the escape, the closing quote (derived from the escape rule; no test beside the source). |
| shell-quoting-010 | command-line-joins-with-space | `commandLine([])` | The empty string (derived: joining no words yields no characters; no test beside the source). |
| shell-quoting-011 | quote-preserves-other-characters | `quoteIfNeeded("a" + newline + "b")` | `'a` + newline + `b'` (derived from the quote rule; no test beside the source). |
| shell-quoting-012 | non-plain-word-quoted | `quoteIfNeeded("$HOME")` | `'$HOME'`, so a shell does not expand it (derived; no test beside the source). |
| shell-quoting-013 | command-line-round-trips | `sh -c 'printf "%s\n" "$@"' sh` followed by `commandLine(["a b", "it's", "$HOME", ""])` | the shell prints `a b`, `it's`, `$HOME` and an empty line, one per line (derived; no test beside the source). |

