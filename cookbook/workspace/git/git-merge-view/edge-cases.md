
- **Null / empty input**: A document with no conflicts never reaches the view (`parse` returns nil); the session shows the diff instead.
- **Boundary values**: A conflict with one side empty (lines deleted on that side) is all filler on that side; choosing it removes the lines from the result.
- **Base missing**: A conflict without a recorded base has Base disabled; `resolved` would refuse `.base` there anyway.
- **No final newline**: The resolved text ends with a newline exactly when the conflicted file did.
- **Concurrent access**: UI thread only; colouring runs in a task and is dropped when a later `show` supersedes it.
- **Error states**: A colouring failure leaves the rows uncoloured.
