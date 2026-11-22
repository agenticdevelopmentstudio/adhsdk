
None — the types read no environment variable or settings key; every value arrives through an initializer argument or a decoded payload. The one fixed value, `appBundleIdentifier`, is taken from `StenographerInstance.baseLabel` rather than spelled here. `counting(from:)` takes the reference time as an argument rather than reading the clock itself, so the caller supplies "now".

