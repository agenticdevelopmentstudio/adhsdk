
- **render-script-element**: `JsonLd` MUST render exactly one `<script>` element with `type="application/ld+json"`.
- **serialize-data**: `JsonLd` MUST write the `data` prop into the script element as the result of JSON serialization of that value.
- **escape-less-than**: `JsonLd` MUST replace every `<` character in the serialized data with the six characters `\u003c`, so no string in the data can close the script element.
- **no-other-escaping**: `JsonLd` MUST NOT escape any character other than `<`; `>` and `&` pass through unchanged.
- **graph-context**: `withWebSite` MUST return an object whose `@context` is `https://schema.org`.
- **graph-array**: `withWebSite` MUST return the entities under an `@graph` array.
- **add-website**: `withWebSite` MUST place a `WebSite` entity first in `@graph`, ahead of the entities taken from `extra`, when none of those entities has an `@type` equal to `WebSite`.
- **website-id**: The added `WebSite` entity MUST carry an `@id` made of `site.url` with all trailing `/` characters removed, followed by `/#website`.
- **website-fields**: The added `WebSite` entity MUST carry the `name`, `url` and `description` of `site`, with `url` unchanged by the trailing-slash trimming applied to `@id`. The source spreads `site` last, so any extra enumerable key on a `site` object (for example its own `@id`) also lands on the entity and overrides the defaults.
- **keep-own-website**: `withWebSite` MUST NOT add a `WebSite` entity when an entity from `extra` already has an `@type` equal to the string `WebSite`, and MUST return that entity unchanged apart from the removal of its `@context`.
- **extra-optional**: `withWebSite` MUST accept an omitted or null `extra` and return a graph holding only the added `WebSite`.
- **extra-forms**: `withWebSite` MUST accept `extra` as a single entity, as a list of entities or documents, or as a `{ "@context", "@graph" }` document.
- **flatten-nested**: `withWebSite` MUST flatten nested lists and nested `@graph` arrays into one flat list of entities.
- **preserve-order**: `withWebSite` MUST keep the entities of `extra` in the order given, after the added `WebSite`.
- **strip-context**: `withWebSite` MUST remove the `@context` key from each entity it takes from `extra`, so that the document carries a single `@context`.
- **no-mutation**: `withWebSite` MUST NOT modify the objects passed in `extra`; each entity is a shallow copy.
- **website-type-exact**: `withWebSite` MUST detect an existing website only by an `@type` that is strictly the string `WebSite`.
- **pure-functions**: `withWebSite` MUST be a pure function with no I/O, and `JsonLd` MUST hold no state.

