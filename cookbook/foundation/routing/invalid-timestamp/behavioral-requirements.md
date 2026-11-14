
- **conforms-to-error**: `InvalidTimestamp` MUST conform to `Error`, so it can be the failure type of a `Result`.
- **carries-message**: `InvalidTimestamp` MUST expose the text given at construction as the read-only property `message`, unchanged.
- **init-takes-message**: `InvalidTimestamp` MUST be constructible with `init(message:)` from any string, and MUST NOT transform or validate it.
- **description-is-message**: `InvalidTimestamp.description` (its `CustomStringConvertible` text) MUST equal `message`.
- **equatable-by-message**: Two `InvalidTimestamp` values MUST compare equal exactly when their `message` strings are equal.
- **no-string-error-extension**: The component MUST NOT make `String` itself an `Error`; the dedicated type is the only error shape for a rejected timestamp.
- **immutable**: `message` MUST be a `let`; a value MUST NOT change after construction.

