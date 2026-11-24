
- **Null and empty input**: An empty `checks` array returns `null` — MUST. A check with `missingEnv: []` is treated as having no missing variables and can be an issue — MUST.
- **Boundary values**: One missing variable or one issue is enough to produce a view; zero of both returns `null` — MUST. A variable named by several checks counts once in `issueCount` — MUST.
- **Concurrent access**: Not applicable — the function holds no state and does not mutate its input, so concurrent calls cannot affect each other; the runtime is single-threaded JavaScript.
- **Error states**: Not applicable — the function performs no I/O and has no `throw` or `try`. It assumes well-typed input; a `null` array argument would throw a native `TypeError` from `filter`, and the source does not guard it, because the TypeScript signature requires an array.
- **Offline or disconnected state**: Not applicable — the function never touches the network. Unreachable providers reach it only as already-decided checks (`unreachable`, `correlated`) produced upstream.
- **Missing-env on an ok check**: A check with `state === "ok"` that still lists `missingEnv` contributes its variables to `missingEnv`, because env collection ignores `state`; `missingEnvError` stays `false` for it — MUST.

