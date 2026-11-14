
- **Data handled**: A commit's repository path and name, SHA, parent, branch, subject and author, the review's summary and a diff of the branch tip in `PartnerReviewStart`; these are the user's source-control data and can include other people's names. `tipDiff` and `summary` can also contain secrets that were committed to source, such as keys or tokens, so consumers MUST treat them as sensitive and avoid logging or persisting `tipDiff`.
- **Storage**: None by these types; the macOS partner store persists reviews.
- **Transmission**: None by these types; `PartnerReviewStart` is returned by the `partner_review_start` tool to the partner process.
- **Retention**: None beyond the lifetime of the value; the store decides how long reviews are kept.

