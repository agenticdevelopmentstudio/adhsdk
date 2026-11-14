
None applicable for the reader's data — `crumbs`, `fields`, `html`, `source`,
and nav node `label`s are all host-supplied. The chrome around them carries
hardcoded English defaults that are not run through any i18n mechanism, though
most are overridable via a prop: `DocNav`'s `title` (`"Navigation"`) and
`closeLabel` (`"Close navigation"`); `DocBreadcrumbs`'s `homeLabel` (`"Home"`); `DocTableOfContents`'s
`title` (`"On this page"`); and `ViewSourceDisclosure`'s `label`
(`"View source"`). Two strings are fixed English with no label prop: the nav section toggle's `aria-label` (`` `${expanded ? "Collapse" : "Expand"} ${node.label}` ``) and `DocBreadcrumbs`'s `aria-label="Breadcrumb"` (the latter can only be replaced through the spread host attributes). `homeHref` (`"/"`) is a destination, not a localized string.

