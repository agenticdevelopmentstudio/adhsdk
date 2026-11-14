
**Decision**: `validateFieldValue` and `coerceFieldValue` are two separate functions with a hard calling-order contract (validate, then coerce only on success), rather than one function that validates-and-normalizes.
**Rationale**: The module's own docblock states the rule precisely: a coercer is total (every input has some branch) but not every branch is a *faithful, non-lossy* reading of the input — an `image` value that is an object would stringify to `"[object Object]"` instead of failing, for example. Splitting the two lets each accepted wire form be judged once, explicitly, for whether coercing it would invent or discard information, rather than silently waving a mangled value through.
**Approved**: pending

**Decision**: `show_if` evaluation fails **open** (shows the field) on an unrecognized `op` or a malformed `in` rule, while `validateFieldValue`, `coerceFieldValue`, and `defaultVisibilityForType` fail **closed** (reject / private) on an unrecognized field type.
**Rationale**: These are different risks pointing in different directions. A `show_if` rule this build cannot read is presumed to be authored by a newer builder; hiding the field would silently drop data the registrant already has no way to fix. An unrecognized *field type*, by contrast, is data whose value this build cannot characterize at all — accepting or publicly exposing it is the greater risk, so the default there is refusal / privacy, not visibility.
**Approved**: pending

**Decision**: `required` is enforced only by `publishBlockers`, at publish time, never at save time.
**Rationale**: The owner-defined form can span many fields across independently-saved sections; enforcing `required` on every save would reject the first section a registrant fills in, citing fields in sections they have not opened yet. Editor and server share this exact function so their checklists can never disagree about what is still missing.
**Approved**: pending

**Decision**: Contact field types (`email`, `phone`, `address`) default to `private` visibility on creation; every other type defaults to `public`.
**Rationale**: Publishing a business phone number or address is a legitimate registry choice, so this is a default, not a ban — but it must be a default nobody is surprised by. Starting contact types closed means publishing one is always a decision someone made, not one they inherited from a generic default.
**Approved**: pending

**Decision**: `searchableText` withholds `email` and `phone` from the anonymous search index even when the field's visibility is `public`.
**Rationale**: A directory is searched by who someone is and what they do, not by their phone number; indexing either would turn the search box into a harvesting oracle (`?q=<number>` would answer "is this number registered?" for a caller who cannot see the profile field itself). This exclusion holds regardless of the owner's visibility choice for the field.
**Approved**: pending

**Decision**: The deep-value comparison behind `eq`/`ne`/`in`/`contains` compares plain objects structurally (via `Object.hasOwn` over own keys) rather than by reference, and caps recursion at 32 levels.
**Rationale**: Two field-for-field identical values fetched independently (e.g., an `address`) are different object references; reference equality made `eq` fail closed on exactly the case its own fail-open policy exists to prevent, silently hiding a dependent field forever. `Object.hasOwn` (not the `in` operator) closes the same untrusted-jsonb-input gap the module's comment on `sameValue` describes, so a payload key like `"constructor"` cannot read as present via the prototype chain. The depth cap bounds the cost of a pathologically deep, but never cyclic, `jsonb` value.
**Approved**: pending

**Decision**: `evaluateShowIf` reads the controlling value as `values[rule.field]` — a direct bracket lookup, not an `Object.hasOwn`-guarded one.
**Rationale**: `rule.field` is owner-authored data from the same untrusted `jsonb` origin the module explicitly reasons about elsewhere (see the decision above), but this particular lookup was not brought under the same guard. See the open question recorded in Behavioral Requirements' cross-cutting notes and the corresponding marker below.
**Approved**: pending

