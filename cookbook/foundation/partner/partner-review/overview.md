
`PartnerReview` is the record of one commit the partner reviews, or declines to review: the repository and commit it names, who wrote it, where its review stands (`PartnerReviewState`), the session that ran it, its summary or skip reason, and the later commits whose review replaced it. `PartnerReviewStart` is the payload `partner_review_start` returns: the review plus the worktree, fix branch, tip diff and steps the partner needs to do it. Both are plain data; the logic that moves a review through its states lives elsewhere.

