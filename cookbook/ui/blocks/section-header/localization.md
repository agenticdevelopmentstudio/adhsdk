
The `title`, `eyebrow`, `help`, and `actions` props accept content supplied — and localized — by the calling component; Section Header performs no text lookup of its own. The one exception is the help trigger's accessible name, which is hardcoded in the source as `aria-label="About this section"` (English only, not externalized to a resource file) — see Compliance. The eyebrow's `uppercase` CSS text-transform is also a locale-sensitive display transform (it can mis-case characters such as German "ß" or Turkish dotted/dotless "i"), not a locale-invariant operation.

