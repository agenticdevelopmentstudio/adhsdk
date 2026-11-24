
- **Toggle button role**: The toggle button element is a native `button`, which provides standard keyboard and screen reader semantics.
- **Toggle button label**: The toggle button MUST have `aria-label="Toggle details"` to communicate its purpose to assistive technology.
- **Root visibility**: The root element MUST use `aria-hidden` to communicate to screen readers whether the disclosure content is visible. When `aria-hidden="true"`, the content is hidden from assistive technology; when `aria-hidden="false"`, it is exposed.
- **Link text**: Each link element's text content is provided by the `label` property or falls back to the `url`, ensuring all interactive elements have accessible text.
- **Minimum touch target**: Ensure the toggle button meets platform-specific minimum touch target size requirements (44×44pt on iOS, 48×48dp on Android, 44×44px on web).
- **Root aria-hidden also hides the toggle button**: `aria-hidden` is set on the root element, which contains the toggle button, so when closed the toggle button itself is removed from the accessibility tree along with the body. A screen reader user cannot reach the button to reopen the content. See **Compliance**.
- **Fixed aria-label overrides the visible title**: The toggle button's accessible name is the static string `aria-label="Toggle details"` regardless of `data.title`, so when a title is rendered its visible text is not part of the accessible name, which fails WCAG 2.5.3 Label in Name. The arrow indicator `span` also carries no `aria-hidden`, so it is not explicitly excluded from the accessibility tree. See **Compliance**.

