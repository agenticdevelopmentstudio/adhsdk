
- **empty-to-prop**: If `to` is an empty string, the anchor renders with `href=""`, which navigates to the current page (browser default behavior).
- **missing-to-prop**: The prop is required by the TypeScript interface; calling without it produces a type error. At runtime, if `undefined` is passed, React omits the `href` attribute entirely (it does not render the literal string `"undefined"`); an `<a>` without `href` is not focusable and is not exposed with the link role.
- **null-or-undefined-children**: If `children` is null or undefined, the anchor renders as an empty element (`<a href="/path"></a>`). The link remains focusable and keyboard-navigable but has no visible or accessible text — see **non-empty-accessible-label**.
- **unsafe-to-scheme**: The component does not validate the destination path or URL scheme; any value passed to `to` — including an unsafe scheme such as `javascript:` — is rendered directly as `href` without sanitization. If `to` can originate from untrusted or user-supplied data, the caller is responsible for validating or allow-listing the scheme before passing it in; see the `input-sanitization` row in Compliance.

