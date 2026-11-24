
Not applicable: ReactionBar is presentational and signals user interactions through the `onToggle` callback only. The caller owns the logic of what a toggle means and any analytics associated with it — logging, event classification, and telemetry belong in the consumer's implementation of `onToggle`.

