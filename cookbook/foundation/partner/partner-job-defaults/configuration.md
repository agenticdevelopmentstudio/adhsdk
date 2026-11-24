| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `codeReviews().scheduleSeconds` | int | 1800 | Default timer interval, in seconds |
| `codeReviews().isEnabled` | bool | false | Whether the job is on at install |
| `codeReviews().steps` | array of `PartnerJobStep` | the three steps above | The default steps; the owner can edit them and reset to this value |
| `codeReviews().guidelines` | string | `codeReviewsGuidelines` | The default guidelines; the owner can edit them and reset to this value |

The ids, `retiredGeneralID`, `codeReviewsGuidelines` and `all` are constants, specified in Behavioral Requirements. The commands and guidelines also rely on values the app supplies when a review starts: `{model}`, `{sha}`, `{fix_branch}` and `{superseded}`, and the tool `partner_review_start` that fills them.
