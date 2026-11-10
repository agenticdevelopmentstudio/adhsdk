
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| window-footer-001 | fixed-height | Component instantiated with any status | Bar height equals 22pt |
| window-footer-002 | top-hairline | Component rendered | Hairline separator visible at top edge |
| window-footer-003 | status-text-leading | `status = "File.txt"` | Text "File.txt" visible at leading edge |
| window-footer-004 | middle-truncation | `status = "very/long/file/path/that/exceeds/available/width.txt"` | Text truncated in middle with ellipsis; full path accessible via tooltip |
| window-footer-005 | hover-tooltip | `status = "example text"` | Hovering over status displays full "example text" |
| window-footer-006 | hover-tooltip | `status = ""` | No tooltip displayed |
| window-footer-007 | status-vertical-centering | Component rendered | Status label vertically centered within 22pt height |
| window-footer-008 | trailing-accessories | `trailingAccessories = [view1, view2]` | Both views rendered horizontally in trailing slot |
| window-footer-009 | trailing-spacing | `trailingAccessories = [view1, view2]` | 6pt horizontal space between view1 and view2 |
| window-footer-010 | trailing-vertical-centering | `trailingAccessories = [view1, view2]` | Accessory views vertically centered within bar |
| window-footer-011 | trailing-accessories | `trailingAccessories = [view1]` then `trailingAccessories = []` | view1 is detached from the view hierarchy (removed as arranged subview and from its superview); trailing slot is empty |
| window-footer-012 | status-accessibility-id | `init(accessibilityPrefix: "project.footer")` | Status label accessibility ID is "project.footer.status" |
| window-footer-013 | full-text-accessible-label | `status` set to a long path that is visually truncated | Status label's accessibility value equals the full, untruncated string |
| window-footer-014 | edge-margins | Component rendered | Status label leading edge is 10pt from the bar's leading edge; trailing accessory stack's trailing edge is 10pt from the bar's trailing edge |
| window-footer-015 | minimum-gap | `status` long enough to approach the trailing edge, `trailingAccessories = [view1]` | Gap between status label's trailing edge and trailing stack's leading edge is at least 8pt |
| window-footer-016 | theme-support | Component rendered under light and dark appearance | Background uses the elevated-surface role, hairline uses the border role, and status text uses the secondary-text role in both appearances |
| window-footer-017 | accessibility-prefix | `init(accessibilityPrefix: "project.footer")` | Component initializes; child identifiers are derived from `"project.footer"` (see **status-accessibility-id**) |

