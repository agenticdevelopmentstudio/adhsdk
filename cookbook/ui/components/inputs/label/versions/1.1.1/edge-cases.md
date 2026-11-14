
- **Missing htmlFor or nesting**: Component renders; however, the label is not semantically associated with a control. This is a consumer error, not a component failure.
- **Empty label text**: Component renders as an empty label element; flexbox layout applies but with no visible content.
- **Multiple children**: Component layout supports multiple children via flexbox with `gap-2` spacing between them.
- **className collision**: The class-merging utility (`cn()`, wrapping `tailwind-merge`) resolves conflicting classes by override, not deduplication: a consumer-supplied class such as `text-lg` replaces the default `text-sm` rather than both being applied.
- **Control nested in label / control after label**: See **peer-disabled-style** — the CSS `:peer` mechanism only matches a later sibling, so a control nested inside the label, or a peer control placed after the label in markup, never triggers the disabled style.

