
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| psv-001 | document-href-required | PaperSearchViewProps with documentHref function | SearchView rendered with documentHref passed through |
| psv-002 | search-source-configuration | Default props (no baseUrl, no authorSlug) | SearchSource configured with endpoints `/public/papers`, `/public/papers/tags`, `/public/papers/categories` and baseUrl `/api` |
| psv-003 | no-store-cache-policy | Any props | SearchSource fetchInit set to `{ cache: 'no-store' }` |
| psv-004 | author-slug-filter | PaperSearchViewProps with authorSlug='author-name' | SearchSource fixedParams includes `{ author: 'author-name' }` (already lowercase) |
| psv-005 | base-url-override | PaperSearchViewProps with baseUrl='/custom/api' | SearchSource baseUrl set to `/custom/api` |
| psv-006 | default-search-label | PaperSearchViewProps with searchLabel='Custom label' | SearchView receives searchLabel='Custom label' |
| psv-007 | default-search-label | PaperSearchViewProps without searchLabel | SearchView receives searchLabel='Search research papers' |
| psv-008 | default-search-placeholder | PaperSearchViewProps with searchPlaceholder='Custom…' | SearchView receives searchPlaceholder='Custom…' |
| psv-009 | default-search-placeholder | PaperSearchViewProps without searchPlaceholder | SearchView receives searchPlaceholder='Search papers…' |
| psv-010 | default-landmark-label | PaperSearchViewProps with searchLandmarkLabel='Custom landmark' | SearchView receives searchLandmarkLabel='Custom landmark' |
| psv-011 | default-landmark-label | PaperSearchViewProps without searchLandmarkLabel | SearchView receives searchLandmarkLabel='Research paper search' |
| psv-012 | document-type-registration | Any props | SearchView receives documentType=markdownDocumentType |
| psv-013 | author-slug-normalization | PaperSearchViewProps with authorSlug='  Jane Doe  ' | SearchSource fixedParams includes `{ author: 'jane doe' }` |
| psv-014 | author-slug-normalization | PaperSearchViewProps with authorSlug='   ' (whitespace only) | SearchSource has no `fixedParams.author` key |
| psv-015 | paper-search-source-factory | `paperSearchSource()` called directly with no options | Returns `{ baseUrl: '/api', endpoints: { results: '/public/papers', tags: '/public/papers/tags', categories: '/public/papers/categories' }, fetchInit: { cache: 'no-store' } }` with no `fixedParams` key |
| psv-016 | search-view-props | Any props | SearchView rendered with exactly the props source, documentType, documentHref, searchLabel, searchPlaceholder, searchLandmarkLabel — no others |

