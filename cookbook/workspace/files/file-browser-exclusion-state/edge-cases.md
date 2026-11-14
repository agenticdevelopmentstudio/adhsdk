
- **Null and empty input**: `onChange` is optional. With it `nil`, a change only
  updates the value (the callback is simply not called). The value is a plain
  `Bool`, so there is no null or empty input to validate. A holder MUST treat
  `nil` as "nobody persists this".
- **Boundary values**: A boolean has two values. Assigning the value the object
  already holds MUST NOT call `onChange`, and the published property still fires
  (see the requirement on equal values), so the two channels disagree on repeats
  by design.
- **Concurrent access**: The type is main-actor isolated, so the compiler keeps
  every access on one actor and changes are serialized. A caller off the main
  actor MUST hop to it first. Ordering of two changes is the order of the
  assignments.
- **Re-entrancy**: `onChange` runs inside the property's did-set. An owner that
  assigns `hidesExcludedContent` again from inside the callback goes through the
  property's observers a second time; the source does nothing to prevent this,
  and the nesting ends only when the nested assignment equals the current value
  (the same-value guard). Owners SHOULD NOT assign the property from the
  callback.
- **Callback retention**: `onChange` is a strong closure reference held by the
  state. An owner that also holds the state (the project owner does) SHOULD
  capture itself weakly in the closure to avoid a cycle; the project owner in
  the same package does so.
- **Error states**: The callback is non-throwing and its return is ignored, so
  the object has no error path. A failure to persist is the owner's concern and
  is invisible here.
- **Offline or disconnected state**: Not applicable: the object does no network,
  file or database access.

