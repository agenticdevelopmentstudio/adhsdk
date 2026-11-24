
- **Bare fragment (#)**: A link with href='#' or an empty href. No target is resolved, so the browser handles the link by default (scrolls to top). The drawer still closes.
- **Non-existent fragment**: A link with href='#missing-section' where no element has id='missing-section'. No element resolves, so default navigation proceeds and the drawer closes.
- **Off-page link**: A link with href='/other-page' or 'https://example.com'. The link is not a same-page fragment, so the drawer closes unconditionally and the browser navigates.
- **Malformed percent-encoding**: A link with href='#bad%ZZ'. Decoding fails, so the raw fragment `bad%ZZ` is used as the id to look up; no error is thrown.
- **Empty links array**: No navigation links provided. Drawer renders with only the close button and optional footer. Tab trap works correctly with remaining focusables.
- **No footer**: Footer prop is undefined. Footer container is not rendered.
- **No brand**: Brand prop is undefined. Brand container is not rendered.
- **Focus outside drawer while open**: Focus ends up outside the drawer (for example, on `body` after a programmatic blur or a browser restoring focus); the next Tab press pulls focus back into the drawer via the trap.
- **Escape key on page with no drawer**: The Escape listener is only active while the drawer is open, so no interference with other page Escape handlers.
- **Tab press with no focusable elements**: If focusable array is empty (e.g., no links, no footer, close button is somehow hidden), Tab does nothing and focus does not move.
- **Browser autofocus behavior**: The drawer is rendered off-screen with a transform (delegated to host CSS) and `inert={true}` when closed, preventing browser autofocus from reaching elements inside.
- **Untrusted link href**: `links[].href` is rendered verbatim as the anchor's `href`; the component does not filter schemes, so a `javascript:` URL in host data would run when clicked. Validating or neutralizing non-http(s)/fragment schemes is the host's responsibility.
- **Very long page with many focusable elements**: All focusables are queried from the DOM every Tab press, not cached, so new or removed focusables are reflected immediately.

