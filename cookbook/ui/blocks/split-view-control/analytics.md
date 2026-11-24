
Not applicable: This component does not emit analytics events directly. Event tracking is the responsibility of the host surface that manages the `useSplitView` hook and calls `setLayout` and `setPane`. If the host wants to track layout or pane changes, it wraps those setters with analytics calls.

