
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| flow-hero-001 | render-headline | `{ headline: "{{headline}}" }` | `<h1>{{headline}}</h1>` rendered in component |
| flow-hero-002 | render-subheading | `{ sub: "{{sub}}" }` | `<p class="lp-hero-sub">{{sub}}</p>` rendered in component |
| flow-hero-003 | render-mark | `{ mark: <img src="{{mark_src}}" alt="{{mark_alt}}" /> }` | Image element rendered without modification |
| flow-hero-004 | render-actions-when-children-provided | `{ children: [<Btn>{{action_label}}</Btn>] }` | `<div class="lp-hero-actions">` wraps children and is visible |
| flow-hero-005 | not-render-actions-when-children-undefined | `{ children: undefined }` | `<div class="lp-hero-actions">` is not rendered |
| flow-hero-006 | render-metadata-when-provided | `{ meta: "{{meta}}" }` | `<p class="lp-hero-meta">{{meta}}</p>` rendered in component |
| flow-hero-007 | not-render-metadata-when-undefined | `{ meta: undefined }` | Metadata paragraph is not rendered |
| flow-hero-008 | render-shot-when-provided | `{ shot: <img src="{{shot_src}}" /> }` | Shot image wrapped in `<div class="lp-hero-shot">` and is visible |
| flow-hero-009 | not-render-shot-when-undefined | `{ shot: undefined }` | Shot container is not rendered |
| flow-hero-010 | support-optional-id | `{ id: "{{hero_id}}" }` | Root `<div>` has `id="{{hero_id}}"` attribute |
| flow-hero-011 | render-root-element | `{ headline: "{{headline}}", sub: "{{sub}}" }` | Root element is `<div class="lp-hero-flow">` |
| flow-hero-012 | render-order | `{ mark: <img />, headline: "{{headline}}", sub: "{{sub}}", children: [<Btn>{{action_label}}</Btn>], meta: "{{meta}}", shot: <img /> }` | Inside the first `Wrap`: mark, then `<h1>`, then `<p class="lp-hero-sub">`, then `<div class="lp-hero-actions">`, then `<p class="lp-hero-meta">`, in that DOM order; `<div class="lp-hero-shot">` renders after that `Wrap`, inside a second `Wrap` |
| flow-hero-013 | not-render-actions-when-children-undefined | `{ children: null }` | `<div class="lp-hero-actions">` renders present but empty (`null` is not `undefined`) |
| flow-hero-014 | not-render-metadata-when-undefined | `{ meta: "" }` | `<p class="lp-hero-meta">` renders present but empty (`""` is not `undefined`) |
| flow-hero-015 | not-render-shot-when-undefined | `{ shot: null }` | `<div class="lp-hero-shot">` renders present but empty (`null` is not `undefined`) |

