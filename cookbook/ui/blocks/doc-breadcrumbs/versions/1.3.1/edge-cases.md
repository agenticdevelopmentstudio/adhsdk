
- **Empty crumbs array**: When `crumbs.length === 0`, component returns null (no render). This avoids displaying a redundant "Home" link pointing to the current page. See **render-nothing-at-root**.
- **Single crumb**: When `crumbs` has exactly one element, it renders as: Home / [CrumbLabel] (where CrumbLabel is plain text).
- **Deeply nested breadcrumbs**: All crumbs except the last are rendered as links; the implementation does not enforce a maximum nesting depth.
- **Missing crumb properties**: Every crumb MUST supply both a `label` and a `path` — the `crumbs` prop type declares both fields as required and non-nullable, so a crumb that omits either, or supplies `null` for one, is a compile-time error at the call site and never reaches the component. The component performs no runtime check for this; the type already excludes the case.
- **Empty strings in crumbs**: If a crumb has an empty `label`, it renders as an empty text node between separators. If `path` is empty, the link's `to` attribute MAY be set to an empty string — the component performs no validation and passes the value through unchanged.
- **Null or undefined crumbs prop**: `crumbs` MUST be a required, non-nullable array; passing `null` or `undefined` is a compile-time error at the call site, not a case the component handles at runtime. The empty array is the one defined "nothing to show" input, and the component MUST treat it as such (see **render-nothing-at-root**), so an absent trail collapses to nothing rather than to a bare "Home" link.

