
Base fixture: every vector's input is merged onto `{ headline: "{{headline}}", sub: "{{sub}}" }`, the two required props, unless the vector sets them itself. A vector that lists `children: undefined`, `meta: undefined` or `shot: undefined` omits that prop from the base fixture.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| flow-hero-001 | headline | `{ headline: "{{headline}}" }` | `<h1>{{headline}}</h1>` rendered in component |
| flow-hero-002 | subheading | `{ sub: "{{sub}}" }` | `<p class="lp-hero-sub">{{sub}}</p>` rendered in component |
| flow-hero-003 | mark | `{ mark: <img src="{{mark_src}}" alt="{{mark_alt}}" /> }` | Image element rendered without modification |
| flow-hero-004 | actions-container | `{ children: [<Btn>{{action_label}}</Btn>] }` | `<div class="lp-hero-actions">` wraps children and is present in the DOM |
| flow-hero-005 | actions-container | `{ children: undefined }` | `<div class="lp-hero-actions">` is not rendered |
| flow-hero-006 | meta-paragraph | `{ meta: "{{meta}}" }` | `<p class="lp-hero-meta">{{meta}}</p>` rendered in component |
| flow-hero-007 | meta-paragraph | `{ meta: undefined }` | Metadata paragraph is not rendered |
| flow-hero-008 | shot-container | `{ shot: <img src="{{shot_src}}" /> }` | Shot image wrapped in `<div class="lp-hero-shot">` and is present in the DOM |
| flow-hero-009 | shot-container | `{ shot: undefined }` | Shot container is not rendered |
| flow-hero-010 | id | `{ id: "{{hero_id}}" }` | Root `<div>` has `id="{{hero_id}}"` attribute |
| flow-hero-011 | root-element | `{ headline: "{{headline}}", sub: "{{sub}}" }` | Root element is `<div class="lp-hero-flow">` |
| flow-hero-012 | child-order | `{ mark: <img />, headline: "{{headline}}", sub: "{{sub}}", children: [<Btn>{{action_label}}</Btn>], meta: "{{meta}}", shot: <img /> }` | Inside the first `Wrap`: mark, then `<h1>`, then `<p class="lp-hero-sub">`, then `<div class="lp-hero-actions">`, then `<p class="lp-hero-meta">`, in that DOM order; `<div class="lp-hero-shot">` renders after that `Wrap`, inside a second `Wrap` |
| flow-hero-013 | actions-container | `{ children: null }` | `<div class="lp-hero-actions">` renders present but empty (`null` is not `undefined`) |
| flow-hero-014 | meta-paragraph | `{ meta: "" }` | `<p class="lp-hero-meta">` renders present but empty (`""` is not `undefined`) |
| flow-hero-015 | shot-container | `{ shot: null }` | `<div class="lp-hero-shot">` renders present but empty (`null` is not `undefined`) |
| flow-hero-016 | mark | `{ mark: undefined }` | No element is rendered for the mark: the first child of the `Wrap` is the `<h1>` |
