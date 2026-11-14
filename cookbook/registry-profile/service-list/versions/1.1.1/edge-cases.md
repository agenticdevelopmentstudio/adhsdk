
- **Empty services array**: Component returns null and renders nothing when `services.length === 0` — see **hide-when-empty** (reference implementation: `ServiceList.tsx`).
- **Single service**: Component correctly renders section, heading, and list with one item.
- **Missing description**: Component conditionally renders the description paragraph only when `service.description` is truthy — see **display-description** (reference implementation: the conditional check in `ServiceList.tsx`).
- **Non-array or null `services`**: The `services` prop is typed as a required array; the component reads `services.length` without a null guard. Passing `null` or `undefined` is outside the documented contract and throws at runtime rather than rendering nothing.
- **Price edge cases**: The `priceText` function (in `ServiceList.tsx`) handles free, barter, absent bounds, equal bounds, and range pricing — see **pricing-free**, **pricing-barter**, **pricing-rate-on-request**, **pricing-single-value**, and **pricing-range**.
- **Unknown pricing model**: An unrecognized `pricingModel` still formats the numeric amount but omits a suffix — see **pricing-suffix**.
- **Currency formatting**: Uses `Intl.NumberFormat('en-US', ...)` with `maximumFractionDigits: 0` to format prices (no decimal places). The locale is hardcoded to `en-US` regardless of the host's locale — see the **locale-aware-formatting** compliance status.
- **List key**: Component uses `service.title` as the React key — see **unique-titles**.

