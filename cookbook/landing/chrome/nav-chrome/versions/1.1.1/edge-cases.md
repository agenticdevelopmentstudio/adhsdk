
- **Bare fragment (#)**: A link with href='#' or an empty href. fragmentId() returns null, and go() allows the browser to handle it (scroll to top). The drawer still closes.
- **Non-existent fragment**: A link with href='#missing-section' where no element has id='missing-section'. fragmentId() returns 'missing-section', getElementById() returns null, go() does not navigate but still closes the drawer and allows the browser to attempt the navigation.
- **Off-page link**: A link with href='/other-page' or 'https://example.com'. fragmentId() returns null (does not start with '#'), go() closes the drawer unconditionally, and allows the browser to navigate.
- **Malformed percent-encoding**: A link with href='#bad%ZZ'. decodeURIComponent() throws, fragmentId() catches and returns the raw fragment 'bad%ZZ'.
- **Empty links array**: No navigation links provided. Drawer renders with only the close button and optional footer. Tab trap works correctly with remaining focusables.
- **No footer**: Footer prop is undefined. Footer container is not rendered.
- **No brand**: Brand prop is undefined. Brand container is not rendered.
- **Focus outside drawer while open**: A click on the scrim or elsewhere that moves focus outside the drawer; the next Tab press pulls focus back into the drawer via the trap.
- **Escape key on page with no drawer**: Escape listener is only attached when drawer is open (useEffect dependency), so no interference with other page Escape handlers.
- **Tab press with no focusable elements**: If focusable array is empty (e.g., no links, no footer, close button is somehow hidden), Tab does nothing and focus does not move.
- **Browser autofocus behavior**: The drawer is rendered off-screen with a transform (delegated to host CSS) and `inert={true}` when closed, preventing browser autofocus from reaching elements inside.
- **Very long page with many focusable elements**: All focusables are queried from the DOM every Tab press, not cached, so new or removed focusables are reflected immediately.

