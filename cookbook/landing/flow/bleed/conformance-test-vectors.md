
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| bleed-001 | render-div | `<Bleed>Content</Bleed>` | Renders a `div` element containing "Content" |
| bleed-002 | apply-base-class | `<Bleed>Content</Bleed>` | Rendered `div` has class `lp-bleed` |
| bleed-003 | side-class, accept-side-prop | `<Bleed side="left">Content</Bleed>` | Rendered `div` has class `lp-bleed--left` |
| bleed-004 | side-class, accept-side-prop | `<Bleed side="right">Content</Bleed>` | Rendered `div` has class `lp-bleed--right` |
| bleed-005 | accept-side-prop | `<Bleed>Content</Bleed>` (no side prop) | Rendered `div` has class `lp-bleed--right` (default) |
| bleed-006 | accept-class-name-prop | `<Bleed className="custom">Content</Bleed>` | Rendered `div` has classes `lp-bleed`, `lp-bleed--right`, `custom` |
| bleed-007 | falsy-class-filter, accept-class-name-prop | `<Bleed className="">Content</Bleed>` | Rendered `div` has classes `lp-bleed`, `lp-bleed--right` (empty className excluded) |
| bleed-008 | accept-children | `<Bleed><span>Text</span><button>Click</button></Bleed>` | Rendered `div` contains both `span` and `button` elements |
| bleed-009 | accept-children | `<Bleed>{null}</Bleed>` | Renders successfully with no content (`null` child) |
| bleed-010 | side-passthrough | `<Bleed side={'center' as unknown as 'left' \| 'right'}>Content</Bleed>` | Rendered `div` has class `lp-bleed--center` |
| bleed-011 | accept-class-name-prop | `<Bleed className="custom-one custom-two">Content</Bleed>` | Rendered `div` has classes `lp-bleed`, `lp-bleed--right`, `custom-one custom-two` (space-separated value appended as-is) |
| bleed-012 | accept-children | `<Bleed><>Content</></Bleed>` | Rendered `div` contains "Content" (fragment's children render inside the `div`) |

