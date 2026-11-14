The component takes a single required prop, `services`, an array of `PublicService`. It has no other configuration options or settings.

| Field | Type | Meaning |
|-------|------|---------|
| title | string | Service name; also the React key (see **unique-titles**) |
| description | string | Description text; the paragraph is omitted when empty |
| pricingModel | string | Open string. Known values: `free`, `barter`, `hourly`, `per_job`, `per_deliverable`, `subscription`. Any other value formats the amount with no suffix |
| priceMin | number or null | Lower price bound; `null` means absent, `0` is a present bound |
| priceMax | number or null | Upper price bound; `null` means absent, `0` is a present bound |
| currency | string | ISO 4217 currency code; an empty value falls back to `USD` |
| unit | string | Carried on the type; not read by this component |
| deliveryMode | string | Carried on the type; not read by this component |
