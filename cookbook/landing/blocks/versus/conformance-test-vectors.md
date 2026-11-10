
| ID | Requirements | Input | Expected |
|----|----|----|----|
| versus-001 | render-both-sides | `them: { title: "Option A" }`, `us: { title: "Option B" }` | Two panels rendered, each with its title in an h3 |
| versus-002 | render-required-title | `them: { title: "Text" }` | h3 element contains "Text" |
| versus-003 | render-optional-lede | `{ lede: "Introduction" }` | Paragraph element renders with "Introduction" |
| versus-004 | render-optional-lede | `lede` omitted entirely | No paragraph element in panel |
| versus-005 | render-optional-points | `{ points: ["Point 1", "Point 2"] }` | Unordered list with two li elements |
| versus-006 | render-optional-points | `{ points: [] }` or `points` omitted | No list element in panel |
| versus-007 | distinguish-sides | `them` and `us` provided | "us" panel carries a distinct marker class (`lp-versus__us`) from "them" (`lp-versus__them`); the two receive different border and background styling |
| versus-008 | render-optional-lede | `lede` passed as an explicitly empty value instead of omitted | Content is defined but empty; a styled empty paragraph still renders — defined-but-empty is not treated as absent |
| versus-009 | consistent-side-structure | Both sides given identical props | Both panels render with identical element structure |
| versus-010 | fixed-side-order | `them` and `us` provided | "them" panel precedes "us" panel in DOM/reading order |
| versus-011 | stack-below-breakpoint | Container narrower than two minimum-width columns plus gap | Layout switches to a single column; "them" panel appears above "us" panel |

