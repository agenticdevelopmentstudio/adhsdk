
The strings below document the intended externalization targets. The current source (`ServiceList.tsx`) hardcodes each of them directly as literal English text — the "Services" heading and every pricing suffix — rather than reading them from a string-key lookup; see the **string-externalization** compliance status.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| services.heading | "Services" | Section heading text; hardcoded literal in `ServiceList.tsx` |
| pricing.free | "Free" | Displayed when pricingModel is "free" |
| pricing.barter | "Trade or barter" | Displayed when pricingModel is "barter" |
| pricing.rate_on_request | "Rate on request" | Displayed when both priceMin and priceMax are null |
| pricing.per_hour | "per hour" | Suffix displayed for hourly pricing model |
| pricing.per_job | "per job" | Suffix displayed for per_job pricing model |
| pricing.per_deliverable | "per deliverable" | Suffix displayed for per_deliverable pricing model |
| pricing.per_month | "per month" | Suffix displayed for subscription pricing model |

