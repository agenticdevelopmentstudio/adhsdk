
**Decision**: The wire types live in a single caseless `Sessions` enum, extended by one file per route family, rather than as top-level types.
**Rationale**: The doc comment calls them "The session daemon's wire types" as one set; a namespace groups them under one qualified prefix, keeps short historical names such as `TurnAggregateDTO` from colliding with other toolkit types, and lets each family's file grow on its own. A caseless enum cannot be instantiated, so the namespace cannot be misused as a value.
**Approved**: pending

**Decision**: The moved types keep the names and fields they had in `StenographerXPCProtocol`.
**Rationale**: The doc comment: they "keep their names and fields inside this namespace, so a payload encoded by the old daemon decodes here unchanged." Keeping the shapes means no translation layer is needed while the old daemon and the new one coexist; the cost is that historical naming is frozen into the new API.
**Approved**: pending

**Decision**: The namespace sits in `AgenticDeveloperHubSDKCore` and imports only Foundation.
**Rationale**: The `Database` tier's daemon code (for example `AccountRouterQuotaSource.swift`, which extends `Sessions.AccountQuotaReadingDTO`, and `LegacySessionImporter`, which reads `Sessions.StenographerBilling.settingsKeyPrefix`) and the clients above it both reach the same types from Core, so dependencies point downward only.
**Approved**: pending

**Decision**: `VisibleText` is an allowlist of general categories, with default-ignorable code points refused first, rather than a denylist of known-bad characters.
**Rationale**: The doc comment: "An allowlist, so a code point nobody thought of is refused by default." The account router's tests show why: zero-width spaces, fillers such as U+3164, variation selectors, combining marks and private-use code points could each split a secret token or hide its prefix from `AccountRouterLog.scrub` if any survived. The cost is that legitimate emoji sequences and decomposed accents are flattened (see Edge Cases).
**Approved**: pending

**Decision**: Template names use the looser `ModelRouterTemplateValidation.isRefusedInName` denylist, not `VisibleText`.
**Rationale**: The `VisibleText` doc comment points to it, and that function's doc comment explains it: a denylist "so emoji (variation selectors, ZWJ sequences) and accents typed as combining marks stay allowed". A name the user types is shown back to that user, while `VisibleText` guards text from clients and upstreams on its way to terminals, logs and stored rows.
**Approved**: pending

**Decision**: Stenographer's billing settings key prefix is a constant in Core, while the key names and billing logic stay in the billing DTOs.
**Rationale**: The doc comment: it is "the one value both of its processes must agree on". Putting it in the lowest tier lets Stenographer's app and daemon, and the legacy importer that reads old Stenographer databases, share one spelling; `BillingSettingsKeys` notes that "a typo on either side is a knob that silently stops working".
**Approved**: pending

