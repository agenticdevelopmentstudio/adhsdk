
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `string \| undefined` | `undefined` | Optional HTML id attribute on the root `<div>` for linking or styling |
| `mark` | `ReactNode \| undefined` | `undefined` | Optional mark/logo element (host supplies its own `<Image>` or `<img>`); when `undefined`, nothing renders in its place |
| `headline` | `ReactNode` | — | Required: a claim describing what the product does, rendered as `<h1>` |
| `sub` | `ReactNode` | — | Required: one-line subheading under the headline, rendered as `<p class="lp-hero-sub">` |
| `children` | `ReactNode \| undefined` | `undefined` | Optional action buttons (bare `Btn` elements in host's order, wrapped in `<div class="lp-hero-actions">`) |
| `meta` | `ReactNode \| undefined` | `undefined` | Optional metadata line (price, platform floor, availability), rendered as `<p class="lp-hero-meta">` and uppercased by stylesheet |
| `shot` | `ReactNode \| undefined` | `undefined` | Optional supporting image below the composition (typically wrapped in the `Bleed` component ([adhsdk.ingredient.landing.flow.bleed](cookbook:feee183a-6488-489e-8e20-c7150bb3e914)) by the host) |

