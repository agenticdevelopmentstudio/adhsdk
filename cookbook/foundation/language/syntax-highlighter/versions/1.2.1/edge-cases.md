
- **Null / empty input**: An empty text is one line with no runs.
- **Boundary values**: Exactly 1 000 000 bytes and a line of exactly 10 000 UTF-16 units are highlighted; one more is nil.
- **Concurrent access**: The actor serialises every call on its one context; JavaScriptCore's API lock covers the thread hops an actor makes.
- **Error states**: A bundle exception or rejected promise throws `SyntaxHighlighterError.javaScript` with the message; malformed output throws `malformedOutput`, an unknown colour `unexpectedColor`.
- **Offline / disconnected state**: Not applicable: everything is local.
- **Cancellation**: A highlight runs to completion once started; callers drop results they no longer need.

