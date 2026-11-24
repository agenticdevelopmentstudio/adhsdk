
- **Corner radius**: None; full-screen on iOS, overlay on web with system-defined styling.
- **Padding**: Transcript stack: 20pt top/bottom, 16pt left/right. Input row: 14pt top/bottom, 16pt left/right. Status row: 16pt left/right.
- **Font**: Input field placeholder: system default (UITextField default). Message bubbles: delegated to `MobileMessageBubbleView`.
- **Background**: Chat surface: `chatSurface` semantic color token. Status row: transparent (inherits surface). Divider: `border` semantic color token.
- **Foreground/Text**: Input field text and placeholder: system default. Send button: system image "arrow.up.circle.fill" (tinted).
- **Border**: Divider between status row and input row: 1pt solid border color.
- **Shadow**: None; surfaces are flat.
- **Min/Max size**: Transcript stack width: equal to the transcript container width (iOS: `UIScrollView` bounds width; web: the overlay's `.persona-chat` container width). Max bubble width: 75% of that container width, or 200pt (iOS) / 200px (web) minimum, whichever is larger.

