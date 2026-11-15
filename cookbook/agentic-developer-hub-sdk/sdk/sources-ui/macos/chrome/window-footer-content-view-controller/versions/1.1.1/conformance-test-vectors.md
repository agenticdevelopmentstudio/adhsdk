
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cvc-001 | content-child | Create with valid content VC and prefix | `contentViewController` is accessible; VC is a child of the container |
| cvc-002 | stacked-layout | Render container with content and footer | Content view's top is at container's top; footer view's bottom is at container's bottom |
| cvc-003 | content-space-fill | Set container's frame to 400×300 | Content view's frame height equals 300 minus `WindowFooterBar.height`; footer's frame height equals `WindowFooterBar.height`; both span the full 400pt width |
| cvc-004 | footer-bottom-position | Render and check constraints | Footer's leading and trailing anchors equal container's; footer's bottom anchor equals container's bottom |
| cvc-005 | status-forwarding | Set `container.status = "Ready"` | `container.footer.status` equals `"Ready"` |
| cvc-006 | status-forwarding | Read `container.status` when footer's status is `"Idle"` | Getter returns `"Idle"` |
| cvc-007 | accessibility-prefix-required | Initialize with a content VC and prefix `"test.footer"` | The footer's status label's accessibility identifier equals `"test.footer.status"`, confirming the prefix was threaded through with no default value available |
| cvc-008 | nscoder-init-unsupported | Attempt `init(coder:)` via archival or Interface Builder | Verified by inspection: the initializer is annotated `@available(*, unavailable)`, so any call site fails to compile; the runtime `fatalError` is defense in depth and is not exercised by a normal XCTest process |

