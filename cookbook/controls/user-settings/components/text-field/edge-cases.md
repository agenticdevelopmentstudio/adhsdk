
- **Empty string input**: When `value` is an empty string, the component MUST render the input element with an empty value and display any provided `placeholder` text.
- **Null or undefined label**: When `label` is `null`, `undefined`, or falsy, no `<label>` element is rendered.
- **Null or undefined hint**: When `hint` is `null`, `undefined`, or falsy, no hint `<p>` element is rendered.
- **Large text input**: When `value` contains many characters (e.g., >10,000), the component MUST display all of them without truncation; overflow behavior (scrolling, wrapping) is controlled by CSS.
- **Multiline with many rows**: When `multiline` is `true` and `value` contains many lines, the textarea MUST display all lines; it has a fixed `rows={4}` and SHOULD scroll vertically if content exceeds visible height (CSS-controlled).
- **Rapid onChange calls**: When the user types quickly, `onChange` callbacks MUST be invoked in sequence for each keystroke; no debouncing or throttling is performed by the component.
- **Disabled input interaction**: When `disabled` is `true`, user interactions (typing, focus) with the input MUST be blocked by the browser's native input element behavior.
- **AutoComplete and password fields**: SecureTextField MUST always prevent autofill to avoid password managers saving API keys or tokens as the site password; this behavior is not configurable.
- **ID collision with external labels**: When an external `<label>` exists with the same `htmlFor` as the generated or provided `id`, both labels will reference the same input; callers MUST avoid duplicate labels.

