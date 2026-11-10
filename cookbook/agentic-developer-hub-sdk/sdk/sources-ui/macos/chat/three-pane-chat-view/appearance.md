
- **Corner radius**: 0 (rectangular panes)
- **Padding**: none at component level; sub-panes (topics, transcript, detail) manage internal spacing
- **Font**: inherited from message and topic content
- **Background**: the topics pane and each visible detail panel share the `--pc-surface` token (transparent until activated, fading in per the visible-pane transition); the chat pane has no separate pane-level background of its own — its transcript and input sub-elements supply theirs.
- **Foreground/Text**: inherited from content
- **Border**: thin separator between panes (1px)
- **Shadow**: none
- **Min/Max size**: Component fills available container; responsively adjusts pane widths based on viewport and content

