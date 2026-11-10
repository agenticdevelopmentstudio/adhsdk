
- The container is a `role="search"` landmark region, optionally named by
  `aria-label` — recommended when a page carries more than one search region.
  `asForm` moves that role onto a `<form>`, which changes nothing for assistive
  tech: a `<form>` is a landmark only once it is named, and this one's name and
  role are the region's.
- The search field is labelled by `search.label` via `aria-label` (icon-only, no
  visible `<label>`), and is a `type="search"` box (`role="searchbox"`).
- Each filter `Select` is labelled by its `label` via `aria-label`.
- The decorative search icon is `aria-hidden` and not focusable.
- All controls are native, so keyboard operability and focus order are inherited
  from the platform.

