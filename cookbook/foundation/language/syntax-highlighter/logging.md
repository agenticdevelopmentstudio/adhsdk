
The bundle's `console` output and skipped user grammar files go to the unified log through `Loggable` (the host app's subsystem; categories `SyntaxHighlighter` and `DirectoryGrammarSource`), `console.warn` and `console.error` at error level.

