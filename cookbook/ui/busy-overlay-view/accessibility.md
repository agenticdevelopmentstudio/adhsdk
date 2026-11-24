
- Role/trait: The overlay sets the progress-indicator accessibility role.
- Label requirements: The accessibility label is the message passed to `show`, and is cleared (set to nil) when no message was given.
- **announce-state-changes**: NEEDS REVIEW: Not implemented in source. The overlay posts no accessibility notification when it appears or disappears and does not move focus; evidence that would settle it is a screen-reader pass checking that a user is told the host is busy and when it is ready again.
- Minimum tap target: Not applicable: the overlay has no tappable control of its own; it intentionally swallows every pointer event.

