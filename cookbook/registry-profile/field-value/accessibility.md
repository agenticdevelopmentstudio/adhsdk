
- Role/trait: Component is a display element, not interactive. Links for URLs are standard, keyboard-accessible `<a>` elements; opening in a new tab via target="_blank" is not itself announced to screen readers (see **url-security-attributes**).
- Label requirements: Image elements use field.label as alt text for screen reader context.
- Text content: All text content is available to assistive technologies; HTML markup in markdown/textarea is rendered as plain text to prevent content injection.
- No interactive controls: Component contains no buttons, form inputs, or keyboard-navigable elements in the default case (URL links are standard navigable elements).

