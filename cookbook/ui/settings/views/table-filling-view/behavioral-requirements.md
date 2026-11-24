
- **main-actor-confined**: The view MUST be confined to the main actor.
- **holds-one-card**: The view MUST hold exactly the card it was given and MUST expose it as `card`.
- **card-pinned-top**: The card MUST be pinned to the view's top, leading and trailing edges, so it is full width and starts at the top.
- **card-height-not-pinned**: The view MUST NOT pin the card's bottom or give it a fixed height; the card's own table height constraint sets the card's height.
- **table-fills-slack**: After each layout, the view MUST set the card's `tableHeight` to its current value plus the difference between the view's height and the card's height.
- **slack-threshold**: The view MUST change `tableHeight` only when that difference is more than half a point either way, so rounding noise does not start a layout loop.
- **shrinks-with-view**: A negative difference MUST shrink the table, so the card follows the view down as well as up.
- **minimum-height**: The view MUST ask its container for at least `minimumHeight` points, default 120, and no more than that; it MUST NOT hold the card's current height as a minimum, so the difference can go negative.
- **card-floor**: The shrinking MUST stop at the card's own floor of one row; the view MUST NOT set a smaller height itself.
- **no-coder-init**: The view MUST NOT be creatable from a decoder.
- **card-autolayout**: The view MUST turn off the card's autoresizing-mask constraints.

