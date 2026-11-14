
- **render-section**: Component MUST render a `<section>` element when the services array contains one or more items.
- **hide-when-empty**: Component MUST NOT render any output when the services array is empty (`services.length === 0`). The `services` prop is a required array; passing `null` or `undefined` is outside the documented contract (see Edge Cases).
- **render-heading**: Component MUST render an `<h2>` heading with the text "Services" within the section. This text is currently a hardcoded literal, not read from a string-key lookup (see the **string-externalization** compliance status).
- **render-list**: Component MUST render an unordered list (`<ul>`) containing one list item per service.
- **display-title**: Component MUST display each service's title as an `<h3>` heading within the list item.
- **display-price**: Component MUST display each service's formatted price using the priceText formatter (see **pricing-free**, **pricing-barter**, **pricing-rate-on-request**, **pricing-range**, **pricing-single-value**, and **pricing-suffix** for the individual formatting rules).
- **display-description**: Component SHOULD display each service's description text when the description property is present and non-empty.
- **semantic-elements**: Component MUST NOT wrap rendered content in non-semantic containers (e.g. generic `<div>` elements). The only elements it renders are `<section>`, `<h2>`, `<ul>`, `<li>`, `<h3>`, and `<p>`.
- **pricing-free**: Component MUST display "Free" when `pricingModel` is `free`, bypassing numeric formatting entirely.
- **pricing-barter**: Component MUST display "Trade or barter" when `pricingModel` is `barter`, bypassing numeric formatting entirely.
- **pricing-rate-on-request**: Component MUST display "Rate on request" when both `priceMin` and `priceMax` are absent and `pricingModel` is neither `free` nor `barter`.
- **pricing-range**: Component MUST display a formatted range (`{min}–{max}`, en dash, no surrounding spaces) when both `priceMin` and `priceMax` are present and differ. Each bound is formatted as currency via `Intl.NumberFormat` with `maximumFractionDigits: 0` and the service's `currency` (defaulting to `USD` when absent).
- **pricing-single-value**: Component MUST display a single formatted currency value — using whichever of `priceMin`/`priceMax` is present — when only one bound is present, or when both bounds are present and equal.
- **pricing-suffix**: Component MUST append a trailing suffix to the formatted price: "per hour" (`hourly`), "per job" (`per_job`), "per deliverable" (`per_deliverable`), "per month" (`subscription`). Component MUST omit the suffix (display the amount alone) when `pricingModel` matches none of these four values.
- **unique-titles**: The `services` array MUST contain unique `title` values. The component uses `service.title` as its React iteration key; duplicate titles are unsupported for stable list reconciliation (see **unique-titles** under Design Decisions).

