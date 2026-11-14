
- `totalPages` of `1` or `0` collapses the whole pager to `null`; hosts must rely on
  that and not add their own visibility guard.
- At the bounds the edge button is `disabled`, so `onPageChange(0)` or
  `onPageChange(totalPages + 1)` can never fire from a click — the component protects
  the edges by disabling rather than by clamping the emitted number.
- An out-of-range `page` from the host (e.g. `page={5}` with `totalPages={3}`) is
  reflected faithfully: the caption shows `"Page 5 of 3"` and `Next` stays disabled
  (`5 >= 3`); clamping the page into range is the host's responsibility, not the pager's.
- Being controlled, nothing changes visually on click until the host applies the new
  `page` — `onPageChange` is a request, not a self-mutation.
- The component performs no validation on `page` or `totalPages`. A `NaN` value fails
  both the `<=` and `>=` bounds checks, so neither `Prev` nor `Next` is disabled and the
  caption renders the literal text `"NaN"`; a negative or non-integer value is compared
  and displayed exactly as given (e.g. `page={-3}` disables `Prev` since `-3 <= 1`, and
  `page={2.5}` renders `"Page 2.5 of 5"`). Passing well-formed integers is the host's
  responsibility.- Clicking `Next` onto the last page disables the button that was just clicked, and `Prev` likewise on the first page. Because the pager uses the native `disabled` attribute and does not move focus, keyboard focus does not stay on a usable control and may fall back to the document; the pager does not manage focus at the edges.
