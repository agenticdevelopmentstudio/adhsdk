
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| trust-001 | list-structure | `items={[<span>Claim A</span>, <span>Claim B</span>]}` | Renders `<ul class="lp-trust"><li><span>Claim A</span></li><li><span>Claim B</span></li></ul>` |
| trust-002 | list-structure | `items={[<span>Claim A</span>]}` | Rendered output contains exactly one `<ul>` element as the root, with no additional wrapping elements |
| trust-003 | container-class | `items={[<span>Claim A</span>]}` | Rendered `<ul>` has `class="lp-trust"` |
| trust-004 | node-items | `items={["Text", <Badge />, <span>Mixed</span>, null]}` | Renders one `<li>` for every entry, in order, including the `null` entry, which renders as an empty `<li>` |
| trust-005 | list-structure | `items={[]}` | Renders an empty `<ul class="lp-trust"></ul>` |

