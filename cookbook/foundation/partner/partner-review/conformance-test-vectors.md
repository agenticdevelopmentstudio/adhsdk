
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-review-001 | initializer-defaults | `PartnerReview(id: "r", repoID: "repo", repoPath: "/r", repoName: "demo", sha: "abc", parent: "p", branch: "main", subject: "s", author: "a", committedAt: any date)`. | `state` is `queued`; `sessionID`, `startedAt`, `finishedAt`, `summary` and `skipReason` are nil; `supersededBy` is empty. |
| partner-review-002 | state-values | Encode each of the five states to JSON. | The strings `queued`, `running`, `done`, `failed`, `skipped`. |
| partner-review-003 | required-keys, state-values | Decode a state from the JSON string `"cancelled"`. | Decoding throws. |
| partner-review-004 | optional-omitted | Encode a review with nil optionals, then decode the result. | The JSON has no `sessionID`, `startedAt`, `finishedAt`, `summary` or `skipReason` key and decoding returns an equal review. |
| partner-review-005 | required-keys | Decode a review JSON object without `supersededBy`. | Decoding throws a missing-key error. |
| partner-review-006 | equality | Two reviews equal except `summary` is nil in one and `"x"` in the other. | They are not equal. |
| partner-review-007 | review-conformances | Read `id` on a review whose `id` is `r1`. | The `Identifiable` identity is `r1`. |
| partner-review-008 | no-lifecycle-rules | Construct a review with `state` `done` and `startedAt` nil and `skipReason` `"x"`. | It is accepted unchanged. |
| partner-review-009 | start-payload | Build a `PartnerReviewStart` with a review, `worktreePath` `/w`, `fixBranch` `fix/x`, `tipDiff` `d` and one step; encode and decode. | The decoded value equals the original. |
| partner-review-010 | superseded-by-meaning | A review with `supersededBy` `["s2", "s3"]`; encode and decode. | The decoded `supersededBy` equals `["s2", "s3"]` in that order. |
| partner-review-011 | review-fields | Build a review with every required field set to a distinct value and read each back. | Each of `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject`, `author`, `committedAt`, `state` and `supersededBy` returns the value given. |
| partner-review-012 | review-optional-fields | Build a review with `sessionID` `"s"`, `startedAt`, `finishedAt`, `summary` `"x"` and `skipReason` `"y"` set; encode and decode. | All five optionals decode to the values given. |
| partner-review-013 | coding-keys | Encode a review with every field set, with a plain `JSONEncoder` and read the object's keys. | The keys equal the property names: `id`, `repoID`, `repoPath`, `repoName`, `sha`, `parent`, `branch`, `subject`, `author`, `committedAt`, `state`, `sessionID`, `startedAt`, `finishedAt`, `summary`, `skipReason`, `supersededBy`. |
| partner-review-014 | required-keys | Decode a whole review JSON object whose `state` is `"cancelled"` and whose other keys are valid. | Decoding throws. |
| partner-review-015 | equality | Two reviews built from identical field values. | They are equal. |
