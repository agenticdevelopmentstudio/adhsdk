
- **Null or empty mail.label**: If `mail.label` is an empty string or null, the rendered anchor has no visible text, failing **link-label** (contact-007); the anchor element still exists and is focusable.
- **Invalid mail.href**: If `mail.href` does not use the `mailto:` scheme, the link renders but may not open the user's mail client as expected, failing **mailto-scheme** (contact-008). This is a source fidelity gap: the component performs no validation.
- **Empty colophon**: If `colophon` is an empty string, the paragraph still renders per **colophon-paragraph**, because the check is for `undefined`, not falsy values; an empty paragraph is rendered to the DOM (contact-009).
- **Children prop omitted**: If `children` is not provided, React passes `undefined` through to `Closer` unchanged (contact-010); `Closer`'s own handling of missing children determines the outcome, since Contact performs no validation.
- **Title prop omitted**: If `title` is not provided, React passes `undefined` through to `Closer` unchanged (contact-011); `Closer`'s own handling of missing title determines the outcome.

