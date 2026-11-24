
- **View shorter than the card's floor** (MUST): The card stops at one row; the owner's window should keep the view at least `minimumHeight` tall.
- **Rounding noise** (MUST): Differences of half a point or less are ignored, so a layout that settles at a fractional height does not loop.
- **Card whose rows fit all** (SHOULD): A card with `fitsAllRows` on sets its own table height from its rows, which this view then overrides on the next layout; owners SHOULD NOT combine the two.
- **Layout before the card is sized** (MUST): The first layout sets the table to fill the view; no earlier height is assumed.
- **Concurrent access** (MUST): Confined to the main actor.
- **Decoding or restoring**: Not applicable: it is built only in code.
- **Network or offline state**: Not applicable.

