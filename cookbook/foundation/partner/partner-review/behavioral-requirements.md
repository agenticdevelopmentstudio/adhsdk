
- **state-values**: `PartnerReviewState` MUST be a string-backed, `Codable` and `Sendable` enum with exactly the cases `queued`, `running`, `done`, `failed` and `skipped`, whose raw values are the case names.
- **review-conformances**: `PartnerReview` MUST be a `Codable`, `Sendable`, `Equatable` and `Identifiable` struct whose identity is `id`.
- **review-fields**: `PartnerReview` MUST carry the required fields `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject` and `author` (strings), `committedAt` (a date), `state`, and `supersededBy` (strings).
- **review-optional-fields**: `PartnerReview` MUST carry `sessionID`, `startedAt`, `finishedAt`, `summary` and `skipReason` as optional values.
- **initializer-defaults**: The initializer MUST default `state` to `queued`, every optional field to nil and `supersededBy` to an empty list; all other fields are required.
- **superseded-by-meaning**: `supersededBy` MUST keep the SHAs it is given in the order given, through encode and decode, and the type MUST NOT add, drop or reorder them; the field is documented in `PartnerReview.swift` as the SHAs of later commits whose review replaced this one.
- **no-lifecycle-rules**: The type MUST NOT enforce state transitions or tie optional fields to a state; it does not check that `skipReason` is set only when `state` is `skipped`, that `finishedAt` follows `startedAt`, or that `summary` is set only when `done`.
- **coding-keys**: Encoding and decoding MUST use the compiler-synthesised keys, equal to the property names; no custom keys or date strategy is set by the type, so the coder in use decides how `committedAt`, `startedAt` and `finishedAt` are written.
- **optional-omitted**: A nil optional field MUST be left out when encoded, as the synthesised encoder does, and a missing optional key MUST decode as nil.
- **required-keys**: Decoding MUST fail when a required key, including `supersededBy` and `state`, is missing, and when `state` holds a value that is not one of the five cases.
- **equality**: Two reviews MUST be equal only when every field is equal.
- **start-payload**: `PartnerReviewStart` MUST be a `Codable`, `Sendable` and `Equatable` struct with `review`, `worktreePath`, `fixBranch` and `tipDiff` (strings) and `steps`, a list of `PartnerJobStep`; its initializer MUST take all five with no defaults.
- **start-source**: `PartnerReviewStart` MUST allow an empty `worktreePath` and `tipDiff` and an empty `steps` list, because a skipped review comes back with those empty; the type MUST NOT reject them.

