
`ActivitySpanDTO` is the wire and storage shape of one contiguous stretch of focus on an allowlisted development app, per its doc comment "One contiguous stretch of focus on an allowlisted development app." It is a plain value type (`Codable`, `Sendable`, `Equatable`, `Identifiable`) with no behavior beyond one derived flag, `isOpen`. It is carried inside `WorkTrackingStatus` as `currentSpan` and is the span unit used by the work-tracking persistence contract. This recipe covers the shape, defaults, sentinel values and mutability rules only.

