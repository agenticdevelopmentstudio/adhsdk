
Not applicable — the only state machine here is `useMarkdownDocument`'s `FetchState<T>` (`idle`/`loading`/`error`/`success`), and it is a data value returned to a caller, not a visual state; see Behavioral Requirements for its transitions.

