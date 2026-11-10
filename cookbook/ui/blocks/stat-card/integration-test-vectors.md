
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-infopanel-shell, title-as-accessible-name, place-link-in-actions, render-a-statrow-per-stat, render-footnote-when-present | `<StatCard title="Traffic" link={{href:'https://us.posthog.com',label:'PostHog'}} stats={[{label:'pageviews · 7d',value:'637'},{label:'visitors · 7d',value:'538'}]} footnote="anonymous · cookieless · approximate" />` | region named "Traffic"; a "PostHog ↗" link with `href="https://us.posthog.com"`; rows "pageviews · 7d"/"637" and "visitors · 7d"/"538"; footnote text present |
| T2 | render-children-after-rows, stack-body-vertically | `<StatCard title="Errors" stats={[{label:'open issues',value:'0'}]}><div>✓ No errors reported</div></StatCard>` | "✓ No errors reported" rendered after the "open issues"/"0" row, inside the one `flex flex-col gap-2.5` body stack |
| T3 | place-link-in-actions | `<StatCard title="Errors" stats={[...]} />` (no `link`) | no `ExternalLink`/anchor in the header actions slot |
| T4 | render-a-statrow-per-stat | `stats={[{label:'open issues',value:'2',tone:'error'}]}` | value "2" carries the error tone (`text-apt-red`) via StatRow |
| T5 | render-footnote-when-present | StatCard with no `footnote` | no footnote caption element rendered |
| T6 | render-infopanel-shell | `icon={<Bug/>}` | icon rendered as the decorative leading glyph (`aria-hidden` via InfoPanel) before the title |
| T7 | forward-classname | `className="col-span-2"` | InfoPanel outer `<section>` carries `col-span-2` |
| T8 | render-actions-after-link, place-link-in-actions | `link={{href:'https://g.example',label:'Grafana'}} actions={<span>healthy</span>}` | header actions slot holds the "Grafana ↗" link, then the status word |
| T9 | spread-host-attributes | `data-testid="monitor-card" data-monitor="lewis" data-phase="ok"` | outer `<section>` carries all three attributes |
| T10 | place-link-in-actions | `<StatCard title="Errors" stats={[{label:'open issues',value:'0'}]} />` (no `link`, no `actions`) | InfoPanel's `actions` prop is `undefined` — the header renders with no actions region at all, not merely an empty one (distinct from T3, which only checks for the missing anchor) |
| T11 | render-children-after-rows, render-footnote-when-present | `<StatCard title="Errors" stats={[{label:'open issues',value:'0'}]} footnote="approximate"><div>✓ No errors reported</div></StatCard>` | within the one body stack, order is the "open issues"/"0" row, then "✓ No errors reported", then "approximate" as the last child |
| T12 | render-actions-after-link, place-link-in-actions | `<StatCard title="Monitor" stats={[{label:'status',value:'ok'}]} actions={<span>healthy</span>} />` (no `link`) | header actions slot renders only `<span>healthy</span>`; no `ExternalLink`/anchor present |

