
| State | Condition | Appearance change |
|-------|-----------|------------------|
| With photo | `photoAttachmentId` present and URL resolves | Photo visible in header |
| Without photo | `photoAttachmentId` absent or URL resolves to null | No photo element rendered |
| With summary | `summary` is truthy | Summary paragraph displayed |
| Without summary | `summary` is falsy | No summary element rendered |
| With metadata | Category, location, or languages present | Metadata rows displayed in definition list |
| Metadata list container | any input | `<dl class="rp__meta">` renders unconditionally, even when it contains no rows |
| With keywords | `keywords.length > 0` | Keywords rendered as list items |
| Without keywords | `keywords.length === 0` | No keywords section rendered |
| Contact available | `contactMode === 'dm'` AND `contact` prop provided | Contact affordance container rendered |
| Contact unavailable | `contactMode !== 'dm'` OR `contact` prop absent | No contact container rendered |
| Field public | `field.visibility === 'public'` | No visibility marker rendered |
| Field authenticated | `field.visibility === 'authenticated'` | "Signed-in members only" marker rendered |
| Field private | `field.visibility === 'private'` | "Private" marker rendered |
| With links | `links.length > 0` | Links navigation section rendered |
| Without links | `links.length === 0` | No links section rendered |

