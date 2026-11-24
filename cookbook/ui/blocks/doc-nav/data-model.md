
- **HdvNavNode**: `{ label: string; href: string; headings?: HeadingEntry[]; children?: HdvNavNode[] }`. A node with a non-empty `children` array is a branch (or, at depth 0, a section); a node with no `children` is a leaf. There is no `kind` discriminator — depth and the presence of `children` are the only distinctions the tree draws.
- **HeadingEntry**: `{ id: string; text: string; depth: number }`. One heading extracted from the rendered document; `id` is the DOM id the component scrolls to and writes onto the URL hash.
- **DocNavTopLink**: `{ label: ReactNode; href: string }`. One fixed row for `topLinks` or `bottomLinks`.

