
- **Corner radius**: Not applicable: the pane draws no rounded shape of its own.
- **Padding**: The terminal view is pinned to the concealed container with four constants set from the terminal appearance's resolved padding for the current theme (the theme's terminal padding override, else the pane content spacing setting). The privacy screen is pinned flush to the pane on all four edges.
- **Font**: The screen message uses the secondary text color role with the body text role, centered, wrapping on words, at most 320 points wide.
- **Background**: The pane and the privacy screen use the window background role of the current theme.
- **Foreground/Text**: The message uses the secondary text role. The eye uses the system symbol `eye.slash` at 48 points regular weight, borderless.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: The pane has a default frame of 800 by 600 points before layout. The stack of eye and message is centered, has at least 20 points to the leading edge and 12 points between the eye and the message.

