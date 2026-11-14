
- **title-prop**: Component MUST accept a `title` prop of type `ReactNode`.
- **children-prop**: Component MUST accept a `children` prop of type `ReactNode`.
- **mail-prop**: Component MUST accept a `mail` prop with `href` (string) and `label` (ReactNode) properties.
- **mail-link-render**: Component MUST render an anchor element with `href` attribute matching `mail.href` and text content matching `mail.label`, appended to `Closer`'s children immediately after the caller-supplied `children`.
- **mailto-scheme**: `mail.href` SHOULD use the `mailto:` scheme so the rendered link opens the user's mail client.
- **colophon-prop**: Component MUST accept an optional `colophon` prop of type `ReactNode`.
- **colophon-paragraph**: Component MUST render a paragraph element with colophon content when `colophon` is not `undefined`.
- **closer-composition**: Component MUST compose the `Closer` component rather than duplicating its markup, passing `title` and `children` through to `Closer` and adding the mail link and optional colophon as further children after the caller's `children`, in that order.
- **css-classes**: The composed element MUST carry both the `lp-closer` class (applied by `Closer`) and the `lp-contact` class; the mailto link MUST carry `lp-mail`; the optional colophon paragraph MUST carry `lp-colophon`.

