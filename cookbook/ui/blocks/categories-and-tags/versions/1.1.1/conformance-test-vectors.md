
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cat-tag-001 | compose-two-fields, render-data-slot | Render with category and tags props | Root element renders with `data-slot="categories-and-tags"` and contains `CategoryField` before `TagSetField` in the DOM |
| cat-tag-002 | share-label-width | Render with both rows | Root element's class list includes the class emitted by `FIELD_LABEL_GROUP_CLASS` (`[--apt-field-label-w:6.5rem]`), setting the custom property via CSS rather than an inline style |
| cat-tag-003 | accept-category-data | `category.label="Type"`, `category.noun="type"`, `category.options=["A","B"]`, `category.value="A"`, `category.onChange=spy` | `CategoryField` receives `label`, `noun`, `options`, and `value` equal to the values in `category`; the `onChange` reference `CategoryField` receives is the same function passed as `category.onChange` |
| cat-tag-004 | accept-category-nodes | `category.nodes=[{...}]` present | `CategoryField` receives the same `nodes` array reference |
| cat-tag-005 | accept-category-rename | `category.onRename=spy` present | `CategoryField` receives the same `onRename` function reference |
| cat-tag-006 | accept-tags-data | `tags.label="Tags"`, `tags.noun="tag"`, `tags.options=["x","y"]`, `tags.value=["x"]`, `tags.onChange=spy` | `TagSetField` receives `label`, `noun`, `options`, and `value` equal to the values in `tags`; the `onChange` reference `TagSetField` receives is the same function passed as `tags.onChange` |
| cat-tag-007 | disable-both-rows | `disabled=true` | Both `CategoryField` and `TagSetField` receive `disabled={true}` |
| cat-tag-008 | forward-classname | `className="custom-class"` | Root element's classList includes `custom-class` alongside the component's own classes |
| cat-tag-009 | use-gap-between-rows | Render with both rows | Root element has 12px of vertical spacing between rows (`gap-3` class on React/Web) |
| cat-tag-010 | require-category-label-noun | Construct props with `category.label` or `category.noun` omitted | TypeScript fails to compile: both are required string properties, not optional |
| cat-tag-011 | require-tags-label-noun | Construct props with `tags.label` or `tags.noun` omitted | TypeScript fails to compile: both are required string properties, not optional |
| cat-tag-012 | preserve-tab-order | Render with both rows and tab in from outside the component | Focus lands on `CategoryField`'s first interactive control before `TagSetField`'s |

