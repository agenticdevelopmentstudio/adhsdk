
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| service-list-001 | render-section, render-heading, render-list | services = [{title: "Web Design", description: "Custom website design", pricingModel: "hourly", priceMin: 75, priceMax: 150, currency: "USD"}] | Renders `<section class="rp-services">` with `<h2 class="rp-services__heading">Services</h2>` and `<ul class="rp-services__list">` |
| service-list-002 | display-title, display-price, display-description, pricing-range, pricing-suffix | services = [{title: "Web Design", description: "Custom website design", pricingModel: "hourly", priceMin: 75, priceMax: 150, currency: "USD"}] (locale: en-US, as hardcoded by priceText) | Renders `<h3>Web Design</h3>`, `<p>Custom website design</p>`, and price as "$75–$150 per hour" |
| service-list-003 | display-price, pricing-free | services = [{title: "Consultation", pricingModel: "free"}] | Renders price text as "Free" |
| service-list-004 | display-price, pricing-barter | services = [{title: "Trade Services", pricingModel: "barter"}] | Renders price text as "Trade or barter" |
| service-list-005 | display-price, pricing-rate-on-request | services = [{title: "Custom Rate", pricingModel: "hourly"}] (with no priceMin/priceMax) | Renders price text as "Rate on request" |
| service-list-006 | display-description | services = [{title: "Service Name", description: null}] | Does not render description paragraph |
| service-list-007 | hide-when-empty | services = [] | Component returns null; no output rendered |
| service-list-008 | semantic-elements | Any valid services array | Every rendered element is one of `<section>`, `<h2>`, `<ul>`, `<li>`, `<h3>`, `<p>` — no other element type appears |
| service-list-009 | pricing-single-value | services = [{title: "Equal Bound", pricingModel: "hourly", priceMin: 100, priceMax: 100, currency: "USD"}] | Renders price text as "$100 per hour" (single value, not a range, since priceMin equals priceMax) |
| service-list-010 | pricing-single-value | services = [{title: "Min Only", pricingModel: "hourly", priceMin: 50, currency: "USD"}] (priceMax absent) | Renders price text as "$50 per hour" |
| service-list-011 | pricing-single-value | services = [{title: "Max Only", pricingModel: "hourly", priceMax: 200, currency: "USD"}] (priceMin absent) | Renders price text as "$200 per hour" |
| service-list-012 | pricing-suffix | services = [{title: "Job Based", pricingModel: "per_job", priceMin: 300, currency: "USD"}] | Renders price text as "$300 per job" |
| service-list-013 | pricing-suffix | services = [{title: "Deliverable Based", pricingModel: "per_deliverable", priceMin: 500, currency: "USD"}] | Renders price text as "$500 per deliverable" |
| service-list-014 | pricing-suffix | services = [{title: "Subscription Based", pricingModel: "subscription", priceMin: 20, currency: "USD"}] | Renders price text as "$20 per month" |
| service-list-015 | pricing-suffix | services = [{title: "Unknown Model", pricingModel: "quote_only", priceMin: 40, currency: "USD"}] | Renders price text as "$40" with no trailing suffix, since "quote_only" matches no entry in the suffix map |
| service-list-016 | unique-titles | services = [{title: "Duplicate", pricingModel: "free"}, {title: "Duplicate", pricingModel: "barter"}] | Both items render on the initial render; duplicate titles used as the React key are unsupported for stable reconciliation across re-renders |

