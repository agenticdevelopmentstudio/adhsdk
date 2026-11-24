
- **Decision**: Topics are automatically extracted from message popover metadata rather than passed as a separate prop.
  **Rationale**: Keeps the component stateless with respect to topics. Tradeoff: the message format must include popover data for topics to appear, and because the recomputed list is committed only when the popover count changes (see **derive-topics-from-messages**), topics do not always reflect the current message set — an update that keeps the same popover count leaves stale topics in place.
  **Approved**: pending

- **Decision**: The visible-topics stack preserves visited topics rather than replacing the view, and entries are only ever appended, never removed by user action.
  **Rationale**: Supports back-navigation and context stacking, letting users maintain multiple active exploration threads. There is currently no mechanism in the source for a user to remove ("pop" or close) a topic from the stack, and topic recalculation does not remove one either: `visibleTopicIndexes` is written only by an append-only effect, so an entry whose topic no longer exists stays in the stack — it is merely skipped wherever it is consumed, and can silently rebind to whatever topic a later recalculation places at that index (see edge case **Visible topics stack out of bounds**).
  **Approved**: pending

- **Decision**: Only one topic can be active (selected) at a time, even though multiple topics may be visible in the stack.
  **Rationale**: Simplifies focus management and connector rendering. Tradeoff: viewing multiple detail panels simultaneously requires a different pattern or component.
  **Approved**: pending

- **Decision**: Arrow up/down navigate between topics; Tab navigates regions.
  **Rationale**: Reserves arrow keys for topic-scoped navigation while keeping Tab for region-scoped navigation. Traceability: `ThreePaneChat.tsx`, the `handleKey` keydown listener registered in the keyboard-navigation effect.
  **Approved**: pending

- **Decision**: Single-character keystrokes (not ctrl/meta/alt) auto-focus the chat input, and the triggering character is delivered into the input rather than discarded.
  **Rationale**: Supports rapid-fire text input without requiring an explicit focus click, common in chat UX. Traceability: `ThreePaneChat.tsx`, the single-character branch of the `handleKey` keydown listener. The topics pane has no letter-search feature of its own, so this heuristic never competes with one — a pressed letter always ends up in the chat input.
  **Approved**: pending

- **Decision**: The connector-drawing component takes an array of `ConnectorPair` objects (from/to IDs), not direct node references.
  **Rationale**: Decouples connector rendering from pane element structure and allows connector updates without querying the DOM. Traceability: `ThreePaneChat.tsx`, the `connectorPairs` computation.
  **Approved**: pending

- **Decision**: The component delegates layout visibility and height recalculation to a dedicated layout hook (`useThreePaneLayout` on web) that measures the frame and available space.
  **Rationale**: Keeps the component focused on state and user interaction while delegating layout logic to a specialized hook. See requirement **recalculate-layout-on-image-load**.
  **Approved**: pending

- **Decision**: The Apple (AppKit) implementation, `ThreePaneChatView.swift`, currently renders `InlineChatView` instead of a full three-pane layout.
  **Rationale**: Keeps `PersonaChatMode` total so hosts can compile against the full mode enum today. The three-pane port — equivalents of TopicsPane, DetailPane, PanelStack, and ConnectorSVG — is deferred deliberately rather than shipped half-built. See the **AppKit / UIKit** platform note.
  **Approved**: pending

