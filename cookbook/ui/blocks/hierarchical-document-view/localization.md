
None applicable for the reader's data — `crumbs`, `fields`, `html`, `source`,
and nav node `label`s are all host-supplied. The chrome around them carries
hardcoded English defaults that are not run through any i18n mechanism, though
each is overridable via a prop: `DocNav`'s `title` (`"Navigation"`) and
`closeLabel` (`"Close navigation"`), and its section toggle's
`aria-label` (`` `${expanded ? "Collapse" : "Expand"} ${node.label}` ``);
`DocBreadcrumbs`'s `homeLabel` (`"Home"`) and `homeHref` (`"/"`), plus its
`aria-label="Breadcrumb"`, which has no prop at all; `DocTableOfContents`'s
`title` (`"On this page"`); and `ViewSourceDisclosure`'s `label`
(`"View source"`).

