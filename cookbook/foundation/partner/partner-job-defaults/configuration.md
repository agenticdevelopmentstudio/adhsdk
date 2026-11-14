
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `codeReviewsID` | string constant | `code-reviews` | Id of the built-in code-reviews job |
| `retiredGeneralID` | string constant | `general` | Id of the retired job, kept for cleanup only |
| `codeReviewsGuidelines` | string constant | the loop text described above | Guidelines of the code-reviews job |
| `codeReviews().scheduleSeconds` | int | 1800 | Default timer interval, in seconds |
| `codeReviews().isEnabled` | bool | false | Whether the job is on at install |
| `all` | array of `PartnerJob` | one job | The list of built-in jobs to seed |

The commands and guidelines also rely on values the app supplies when a review starts: `{model}`, `{sha}`, `{fix_branch}` and `{superseded}`, and the tool `partner_review_start` that fills them.

