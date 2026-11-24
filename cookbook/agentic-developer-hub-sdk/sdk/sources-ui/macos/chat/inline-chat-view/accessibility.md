
- **Role**: Chat interface / message list. Apple: NSView with `ChatStateObserver` and focus tracking; web: generic div with role deferred to children.
- **Keyboard navigation**: Tab navigates to send button; Return submits from input field; Escape disengages (Apple only).
- **Focus indicators**: Input field displays focus ring when active (platform default).
- **Labels**: Placeholder text in input field conveys purpose; send button has accessibility description (Apple "Send").
- **Screen reader**: Thinking indicator announces "Thinking" or configured status text; message bubbles read via child components (`MessageBubbleView` on Apple, `Transcript` on web).
- **Participant side**: Bubbles are visually separated by side (right = local, left = remote); no explicit role mapping.
- **Minimum tap target**: Send button 18pt (Apple SF symbol, >44×44pt); input field assumed ≥44pt height.
- **Status announcement**: Typing indicator state changes (appears/disappears, text updates) should be announced; implementation deferred to `ThinkingIndicatorView`.

