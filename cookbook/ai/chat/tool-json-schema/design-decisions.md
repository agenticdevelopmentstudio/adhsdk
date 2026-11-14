
**Decision**: All tool sources build parameter schemas through this one helper instead of hand-writing JSON.
**Rationale**: The doc comment says it exists so "every tool source spells an object schema the same way". A single builder keeps the `type`, `properties` and `required` shape uniform across sources, and the sorted-key output makes a schema's bytes stable.
**Approved**: pending

**Decision**: `required` is always emitted, as an empty array when no argument is required.
**Rationale**: Some schema consumers expect the key to be present; always emitting it removes a case. The source does it by giving the parameter a default of `[]`.
**Approved**: pending

**Decision**: Serialization failure falls back to the bytes `{}` with no signal.
**Rationale**: The source uses `try?` with a `?? Data("{}".utf8)` default, favoring a non-optional return type over reporting an error. The cost is that a failure produces a schema with no `type`; see the open question on `schema-serialization-fallback`.
**Approved**: pending

**Decision**: Fragments are untyped `[String: Any]` dictionaries rather than a schema type.
**Rationale**: The source keeps the helper tiny; any valid JSON-schema fragment (for example one with `enum` or `items`) can be passed to `object`, at the price that `object` cannot validate it.
**Approved**: pending

