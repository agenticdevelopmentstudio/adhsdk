
**Decision**: `<` is escaped as `\u003c` and no other character is.
**Rationale**: A `</script>` inside any string would end the element and let the rest of the data run as markup. Escaping `<` alone closes that hole, and `\u003c` is read back as `<` by any JSON parser, so the data is unchanged for crawlers.
**Approved**: pending

**Decision**: `JsonLd` writes the text through `dangerouslySetInnerHTML` instead of as a React child.
**Rationale**: React escapes text children as HTML, which would turn quotes into entities and break the JSON. The `<` escape stands in for that protection.
**Approved**: pending

**Decision**: `withWebSite` adds a `WebSite` for every site unless the page declares one.
**Rationale**: The source comment says the entry tells an answer engine that the name, the description and the origin belong together, "which every site can say without writing anything new".
**Approved**: pending

**Decision**: The `WebSite` `@id` is the origin with trailing slashes trimmed plus `/#website`.
**Rationale**: A stable identifier lets other entities in the graph refer to the site; trimming keeps `https://x.example/` and `https://x.example` from producing different identifiers.
**Approved**: pending

**Decision**: `@context` is stripped from every incoming entity and one is set on the result.
**Rationale**: A graph carries one context. Hosts can pass whole documents, single entities or lists without caring which form a helper returned.
**Approved**: pending

**Decision**: An existing website is recognized only by `@type` equal to the string `WebSite`.
**Rationale**: This is the source's check, and it is technical debt that affects behavior: a `WebSite` declared with an array type is not detected and is duplicated. A host that declares its own SHOULD use the string form.
**Approved**: pending

**Decision**: There is no guard around serialization.
**Rationale**: The data is authored by the host and static in practice. Throwing at render time makes a bad value visible during development, and the source adds no fallback.
**Approved**: pending

