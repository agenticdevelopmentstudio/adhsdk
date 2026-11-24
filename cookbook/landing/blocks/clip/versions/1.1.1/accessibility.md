
- **Role**: The component renders a native HTML `<video>` element. `<video>` has no implicit ARIA role; the accessible name comes entirely from the `aria-label` attribute.
- **Label requirements**: MUST have a `label` prop provided so the video element carries an `aria-label` (see **aria-label**) describing the video content. This is the accessible name for screen readers.
- **Announce state changes**: The component does not announce state changes via ARIA live regions; the user controls playback through visible controls when `prefers-reduced-motion` is true.
- **Motion preference**: MUST respect `prefers-reduced-motion: reduce` per [WCAG 2.1 Animation from Interactions](https://www.w3.org/TR/WCAG21/#animation-from-interactions). When enabled, the component must not autoplay or loop without explicit user action.
- **Keyboard control**: When controls are visible (reduced motion), the native video element provides keyboard support (spacebar, arrow keys) for playback control.
- **Minimum tap target**: Native video controls (when visible) are sized and hit-tested by the browser; this component does not control or verify their tap-target dimensions against platform minimums (44×44pt on iOS, 48×48dp on Android).

