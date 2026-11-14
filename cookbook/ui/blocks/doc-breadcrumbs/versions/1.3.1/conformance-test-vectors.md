
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| breadcrumb-001 | render-navigation-element | `crumbs={[{label:"Docs", path:"/docs"}]}` | Renders `<nav aria-label="Breadcrumb">` |
| breadcrumb-002 | include-home-crumb | `crumbs={[{label:"Docs", path:"/docs"}]}` | First item is a link to `/` with label "Home" |
| breadcrumb-003 | render-crumbs-list | `crumbs={[{label:"Docs", path:"/docs"}]}` | Uses `<ol>` and `<li>` elements |
| breadcrumb-004 | render-current-as-text | `crumbs={[{label:"Docs", path:"/docs"}, {label:"API", path:"/docs/api"}]}` | Last crumb "API" is plain text, not a link |
| breadcrumb-005 | render-ancestors-as-links | `crumbs={[{label:"Docs", path:"/docs"}, {label:"API", path:"/docs/api"}]}` | First crumb "Docs" is a link to "/docs" |
| breadcrumb-006 | separate-crumbs | `crumbs={[{label:"Docs", path:"/docs"}]}` | "/" character appears between home and first crumb |
| breadcrumb-007 | render-nothing-at-root | `crumbs=[]` | Component returns null (renders nothing) |
| breadcrumb-008 | accept-custom-link-component | `crumbs={[{label:"Docs", path:"/docs"}]} LinkComponent={CustomLink}` | Uses CustomLink instead of DefaultDocLink |
| breadcrumb-009 | accept-custom-home-label | `crumbs={[{label:"Docs", path:"/docs"}]} homeLabel="Dashboard"` | Home link displays "Dashboard" instead of "Home" |
| breadcrumb-010 | accept-custom-home-href | `crumbs={[{label:"Docs", path:"/docs"}]} homeHref="/app"` | Home link points to "/app" instead of "/" |
| breadcrumb-011 | accept-crumbs-array | `crumbs={[{label:"Docs", path:"/docs"}, {label:"Guides", path:"/docs/guides"}]}` | Both crumbs render in correct order |
| breadcrumb-012 | forward-html-attributes | `crumbs={[{label:"Docs", path:"/docs"}]} data-testid="breadcrumb"` | `<nav>` element has `data-testid="breadcrumb"` |

