
The bundle's `console` output and skipped user and extension grammar files go to the unified log through `Loggable` (the host app's subsystem; categories `SyntaxHighlighter`, `DirectoryGrammarSource` and `GrammarContributionPoint`), `console.warn` and `console.error` at error level.

