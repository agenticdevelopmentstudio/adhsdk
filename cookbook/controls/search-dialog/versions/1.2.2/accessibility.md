
- **Role/trait**: Dialog (`role="dialog"`); form with search role (`role="search"`); results are buttons (`type="button"`).
- **Label requirements**: Input has `aria-label="Search"`. Section headings and result buttons derive meaning from text content; no explicit ARIA labels on results.
- **Announce state changes**: The component does not implement live region announcements. Result count and selected result changes are not communicated to screen reader users as the user navigates results or performs searches; the results container carries no `aria-live` or `aria-atomic` attributes in the source.
- **Minimum tap target**: Not specified in source; result buttons and input field target sizes are stylesheet-driven. WCAG 2.5.8 Target Size (Minimum, Level AA) requires 24×24 CSS px; WCAG 2.5.5 Target Size (Enhanced, Level AAA) requires 44×44 CSS px. Platform guidance: 44×44pt minimum on iOS, 48×48dp on Android.
- **Keyboard navigation**: Fully keyboard operable. Input accepts focus; arrow keys (via `state.handleKey`) navigate results; Enter selects; Escape dismisses.
- **Modal semantics**: `aria-modal="true"` tells assistive technology that content outside the dialog is inert; it does not by itself trap focus. The source implements neither a focus trap nor focus restoration to the previously focused element on close (see **Announce state changes** for the related screen-reader gap). Backdrop click and Escape dismiss the dialog (see **dismissible-backdrop**, **escape-dismisses**).

