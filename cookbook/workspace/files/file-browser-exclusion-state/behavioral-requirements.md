
- **default-hides-excluded**: Constructing the state with no argument MUST set
  `hidesExcludedContent` to `true`.
- **init-stores-given-value**: Constructing the state with an explicit
  `hidesExcludedContent` argument MUST store that value.
- **init-does-not-notify**: Constructing the state MUST NOT call `onChange`.
- **on-change-nil-by-default**: A newly constructed state MUST have a `nil`
  `onChange`, so a change made before an owner assigns one is not reported to
  anyone.
- **change-notifies-owner**: Assigning `hidesExcludedContent` a value different
  from its current value MUST call `onChange` exactly once, with the new value.
- **same-value-is-silent**: Assigning `hidesExcludedContent` a value equal to its
  current value MUST NOT call `onChange`.
- **notify-after-store**: The `onChange` call MUST happen after the new value is
  stored, so reading `hidesExcludedContent` inside the callback returns the new
  value.
- **notify-is-synchronous**: `onChange` MUST be called synchronously from the
  assignment, on the same actor that made the assignment, with no hop and no
  delay.
- **nil-callback-is-noop**: Assigning a changed value while `onChange` is `nil`
  MUST update `hidesExcludedContent` and MUST NOT fail.
- **callback-replaceable**: `onChange` MUST be a settable property, so an owner
  can assign it after construction and can replace it later.
- **publishes-for-observers**: `hidesExcludedContent` MUST be observable through
  the Combine `ObservableObject` machinery, so a view or controller can
  subscribe to its changes.
- **publisher-fires-before-store**: A subscriber to the published
  `hidesExcludedContent` publisher is notified before the stored value is
  updated, because the property wrapper publishes from the will-set step. A
  subscriber that reads the property back MUST defer the read (the file browser
  view controller hops to the main run loop for this reason, per its source
  comment).
- **publisher-fires-for-equal-values**: Every assignment to the published
  property MUST be visible on the publisher, including an assignment of the
  current value; only `onChange` is guarded against equal values, so a
  subscriber that must ignore repeats applies its own de-duplication (the file
  browser view controller applies `removeDuplicates`).
- **main-actor-isolated**: The type MUST be isolated to the main actor; every
  read, write and callback runs on the main actor.
- **shared-by-reference**: The type MUST be a reference type, so every holder of
  one instance sees the same value after any holder changes it.
- **no-persistence-here**: The type MUST NOT write the value anywhere on its own;
  persistence is the `onChange` owner's job.

