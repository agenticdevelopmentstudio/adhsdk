
- **state-values**: `PartnerReviewState` MUST be a string-backed, `Codable` and `Sendable` enum with exactly the cases `queued`, `running`, `done`, `failed` and `skipped`, whose raw values are the case names.
- **review-conformances**: `PartnerReview` MUST be a `Codable`, `Sendable`, `Equatable` and `Identifiable` struct whose identity is `id`.
- **review-fields**: `PartnerReview` MUST carry the required fields `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject` and `author` (strings), `committedAt` (a date), `state`, and `supersededBy` (strings).
- **review-optional-fields**: `PartnerReview` MUST carry `sessionID`, `startedAt`, `finishedAt`, `summary` and `skipReason` as optional values.
- **initializer-defaults**: The initializer MUST default `state` to `queued`, every optional field to nil and `supersededBy` to an empty list; all other fields are required.
- **superseded-by-meaning**: `supersededBy` MUST hold the SHAs of later commits whose review replaced this one (the source comment).
- **no-lifecycle-rules**: The type MUST NOT enforce state transitions or tie optional fields to a state; it does not check that `skipReason` is set only when `state` is `skipped`, that `finishedAt` follows `startedAt`, or that `summary` is set only when `done`.
- **coding-keys**: Encoding and decoding MUST use the compiler-synthesised keys, equal to the property names; no custom keys or date strategy is set by the type, so the coder in use decides how `committedAt`, `startedAt` and `finishedAt` are written. The `partner_review_start` tool encodes with sorted keys and ISO 8601 dates; the macOS store does not use `Codable` for reviews and writes each field to its own column, with `supersededBy` as a JSON array of strings.
- **optional-omitted**: A nil optional field MUST be left out when encoded, as the synthesised encoder does, and a missing optional key MUST decode as nil.
- **required-keys**: Decoding MUST fail when a required key, including `supersededBy` and `state`, is missing, and when `state` holds a value that is not one of the five cases.
- **equality**: Two reviews MUST be equal only when every field is equal.
- **start-payload**: `PartnerReviewStart` MUST be a `Codable`, `Sendable` and `Equatable` struct with `review`, `worktreePath`, `fixBranch` and `tipDiff` (strings) and `steps`, a list of `PartnerJobStep`; its initializer MUST take all five with no defaults.
- **start-source**: `PartnerReviewStart` is what `partner_review_start` returns; this type defines the shape only, and the tool that builds it lives in the macOS partner feature (`ReviewService`). A commit no longer in its branch comes back as a skipped review with an empty `worktreePath` and `tipDiff` and no `steps`; the shape allows those empty values. `supersededBy` is filled from the commits after the reviewed one, on the branch, that touch the files the commit changed, and `tipDiff` is cut at 8,000 bytes by default.

