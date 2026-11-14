
DocBreadcrumbs renders a semantic breadcrumb trail for document navigation. Whenever it renders, it includes a home crumb first and then the ancestor trail, with the current page (last crumb) rendered as plain text rather than a link. When the component is at the root (no ancestors), it renders nothing to avoid showing a redundant "Home" link pointing to the current page.

