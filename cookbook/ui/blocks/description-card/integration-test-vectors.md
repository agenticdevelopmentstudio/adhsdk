
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-title, render-description-as-plain-text | `<DescriptionCard title="Plan" description={'line one\nline two'} />` | title "Plan"; a `<p>` with `whitespace-pre-wrap` containing both lines |
| T2 | render-description-through-renderer | `description="**hi**" renderMarkdown={md => <div>{md.toUpperCase()}</div>}` | the renderer's output is shown, called with `**hi**` |
| T3 | render-nothing-when-empty | `<DescriptionCard />` and `<DescriptionCard title="" description="" />` | nothing rendered |
| T4 | omit-empty-content | `<DescriptionCard title="Only title" />` | no card-content element |
| T5 | render-title | `<DescriptionCard description="just text" />` | no card-header element |
| T6 | render-card-shell | `className="col-span-2" data-testid="dc"` | the card carries both |
