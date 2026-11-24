
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| shot-001 | frame-chrome | title="My App" | Renders `.lp-shot` with a `.lp-shot__bar` containing three `.lp-shot__dot` spans and a title |
| shot-002 | title-in-bar | title="MyWindow" | "MyWindow" appears as text in `.lp-shot__name` |
| shot-003 | media-verbatim | `media={<img src="x.png" />}` | The `<img>` element is rendered directly as the child of `.lp-shot`, replacing the placeholder; no wrapping element, no CSS class added |
| shot-004 | placeholder-when-no-media | media undefined | `.lp-shot__placeholder` renders with the diagonal hatch background instead of media |
| shot-005 | caption-in-placeholder | caption="Screenshot pending" | Placeholder contains "Screenshot pending" inside a `<b>` element |
| shot-006 | pending-label-above-caption | pendingLabel="Capture in progress" | "Capture in progress" renders before (above) the `<b>` caption inside `.lp-shot__placeholder` |
| shot-007 | pending-label-above-caption | pendingLabel undefined | Placeholder renders only the `<b>` caption; no pending-label content precedes it |
| shot-008 | pending-label-verbatim | `pendingLabel={<span className="custom">Loading</span>}` | Renders the `<span>` with its class unmodified |
| shot-009 | falsy-pending-label-omitted | pendingLabel="" | No visible pending-label text renders; placeholder shows only the caption |
| shot-010 | media-verbatim | `media={<video src="x.mp4" />}` | `.lp-shot__placeholder` is absent; only the given `<video>` element renders |
| shot-011 | caption-in-placeholder | caption="" | Placeholder renders an empty `<b>` element; no caption text is visible |
| shot-012 | title-in-bar | title="" | `.lp-shot__name` renders empty; the frame and dots still display |

