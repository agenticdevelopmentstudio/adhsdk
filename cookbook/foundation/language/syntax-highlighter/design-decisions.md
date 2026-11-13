
**Decision**: Promises are awaited through `then` callbacks inside the actor's own call, never by running a run loop.
**Rationale**: JavaScriptCore drains microtasks when the outermost call returns, and the bundle uses nothing but promises, so every promise settles before the call returns; spinning a run loop from an actor would block a cooperative thread and could re-enter unrelated work.
**Approved**: pending

**Decision**: `WebAssembly.instantiate` is replaced in the context with a synchronous `Module` + `Instance` that returns a resolved promise.
**Rationale**: An asynchronous compile may finish on JavaScriptCore's deferred-work timer, which only a run loop fires; compiling synchronously keeps `create` inside the one call regardless of JIT availability.
**Approved**: pending

**Decision**: Over the limits the answer is nil (uncoloured), not a partial highlight.
**Rationale**: A huge or minified file costs seconds in an interpreted engine; showing it plain keeps the viewer responsive and the rule simple.
**Approved**: pending

