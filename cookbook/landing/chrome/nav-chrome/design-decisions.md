
**Tab trap listens on `document`, not the drawer**

**Decision**: The keyboard event listener for Tab and Escape is attached to `document`, not to the drawer element itself.
**Rationale**: This ensures Tab is caught even when focus has escaped the drawer (for example, via a stray click on the scrim). A listener on the drawer alone would miss those cases and let Tab move focus outside the drawer.
**Approved**: pending

**`inert` on the closed drawer**

**Decision**: The drawer is marked `inert={true}` when closed.
**Rationale**: This removes all closed-drawer elements from the accessibility tree and tab order, preventing keyboard and screen reader users from reaching them. It is more comprehensive than `tabIndex={-1}` alone, which would hide the drawer from Tab but not from assistive technology.
**Approved**: pending

**`wasOpen` gates focus return**

**Decision**: A ref (`wasOpen`) records whether the drawer has previously been open, and the focus-return effect only returns focus to the burger button when that ref is `true`.
**Rationale**: React runs effects after the initial render too, so without this gate the focus-return effect's "drawer is closed" branch would fire on mount and move focus to the burger button the user has not yet interacted with. `wasOpen` starts `false` and is only set once the drawer has actually been opened, so the gate is a no-op on mount and only fires after a real open→close transition.
**Approved**: pending

**Fragment targets resolved with `getElementById`, not `querySelector`**

**Decision**: Fragment targets are looked up with `document.getElementById(id)` rather than `document.querySelector('#' + id)`.
**Rationale**: An HTML `id` can legally contain characters that are invalid or require escaping in CSS selector syntax — for example, one that starts with a digit (`2024-results`) or contains a colon or dot. `querySelector` would throw a `SyntaxError` on such ids unless manually escaped, whereas `getElementById` takes the raw string and simply returns `null` when nothing matches, letting the fallback path run instead of throwing. (A `mailto:` link never reaches this lookup at all — `fragmentId()` only looks at hrefs that start with `#`.)
**Approved**: pending

**Smooth scrolling is the host's CSS, not the component's**

**Decision**: The host sets `scroll-behavior: smooth` on its own `html` element; the component does not set it anywhere.
**Rationale**: This lets the host control scroll behavior globally, so smooth scrolling works the same way whether a fragment link is clicked from the drawer or anywhere else on the page. The component's only job is to call `scrollIntoView()` on the resolved target and move focus to it.
**Approved**: pending

**Drawer positioning via CSS transform, not JavaScript**

**Decision**: The drawer is positioned off-screen and on-screen by the host's `.lp-drawer` / `.lp-drawer--open` CSS rules, not moved by JavaScript.
**Rationale**: This keeps the animation in CSS and lets the host use transitions or media queries to adjust positioning for different screen sizes without touching the component.
**Approved**: pending

**Burger and close buttons share a class**

**Decision**: Both the burger and the close button use the `.lp-burger` class, with `.lp-drawer-close` added to the close button.
**Rationale**: This allows shared styling for button dimensions and appearance, with additional rules in `chrome.css` for the close button's X-icon transformation via `.lp-drawer-close`.
**Approved**: pending

