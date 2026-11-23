
**Decision**: the server-bags delete confirmation's removal message ("will be deleted. Anything reading it gets nothing <em dash> there is no default.") is declared independently rather than reusing the feature-flags delete confirmation's message ("will be removed. Anything reading it falls back to its default."), even though both are one-line "what deleting this costs" strings for a very similar delete-confirmation UI.
**Rationale**: the source's own comment states the reason directly: server bags have no defaults to fall back to, unlike feature flags - deleting one leaves readers with nothing at all. Borrowing the flags' message promised a fallback that does not exist, in the one dialog whose job is to say what deleting costs. Sharing the string would have made the confirmation dialog lie about what actually happens.
**Approved**: pending

**Decision**: the storage-tokens create form's save action uses a three-way catch (a conflict error → friendly message; any other shared error kind → rethrown as-is; anything else → a generic unexpected error) instead of the shared error-wrapping convention every other create/update/delete call in this component uses.
**Rationale**: the conflict case needs its own friendly text rather than whatever detail the backend's conflict response carries, and the source chooses to discard a non-shared-error-kind failure's own message in favor of a generic one rather than risk surfacing raw transport detail from a mint request specifically. This is documented here as an observed, intentional divergence rather than corrected to match the shared error-wrapping convention. It applies to the Swift implementation only; the alternate client has no equivalent create-error taxonomy to diverge from.
**Approved**: pending

**Decision**: the storage-tokens detail sources its post-reveal notice text from a constant declared in a sibling Applications module (Applications' own token-reveal notice), rather than declaring its own copy.
**Rationale**: the source's own comment states this directly - the reveal-once behavior exists specifically because that sibling constant's promise ("you won't be able to see it again") must actually hold; the same lifecycle and constant are documented as canonical in the sibling recipe [adhsdk.ingredient.adh.hub.security.authentication-client](cookbook:65fbb2b1-ca41-499f-ac03-7ecc0e206dcc), which this ingredient treats as the complete reference for that shared behavior rather than re-deriving it here. The coupling means a future rename of that constant would need to be tracked across both modules with no compiler-enforced link beyond the direct reference. This is a cross-module source-file coupling specific to the Swift codebase's module layout.
**Approved**: pending

**Decision**: JSON-shape validation for a server bag's value lives inside the value-parsing step on the Swift implementation, combining transport-adjacent orchestration with domain validation in one type; on the web implementation, the equivalent validation is not in the given data client at all - it lives in a sibling `features/ecosystem-config` package's dialog-state module.
**Rationale**: the two platforms split responsibilities differently: the Swift topic types are the single place that both talk to the data source and build the declarative form, so validation naturally lives there too; the web implementation keeps its data-client layer free of any dependency on UI-adjacent validation state, pushing that concern into the package that owns the dialog. Both are internally consistent with their own layering; this ingredient documents the divergence rather than treating either as a gap. It applies differently to each of the two reference implementations, by design.
**Approved**: pending

**Decision**: on the web implementation, origin-format validation for a sign-in app's `allowedReturnOrigins` (mirroring the Swift implementation's origin-validation/canonicalization steps) is not present in the given data client - it lives in a UI-pane file's own validation helpers, outside this component's given sources.
**Rationale**: this follows the same data-client/features-package split as the server-bag JSON validation above, and was confirmed by reading the actual caller rather than assumed, per this ingredient's requirement to resolve an apparent gap against the real codebase before marking it unresolved. It applies to the web implementation.
**Approved**: pending

**Decision**: feature-flag keys SHOULD be restricted so they cannot contain the composite id's `:` delimiter, either by the slug-pattern restriction already applied to the sign-in-app `clientId` field and the storage-token `name` field or by escaping the key inside the composite id. Neither is implemented yet.
**Rationale**: the key is embedded unescaped in a colon-delimited composite id, so a colon in a key could collide with another item's id; a validating pattern on the key field, or confirmation from the composite-id format's other consumers that a reserved character cannot collide, would close the gap.
**Approved**: pending

**Decision**: one sync-tables pane, in this package, serves both the admin
console and the hub's `[workspace]/sync` page; the route family is a prop.
**Rationale**: the two surfaces differ only in who may call the backend, and the
backend already shares one handler set between its two route families. A second
pane would be two copies of the same list that nothing keeps in step. This package
is the lowest tier that holds an ecosystem's configuration panes, and the admin
console already sits above it. The owner approved this in the Temporal plan on 2026-11-13.
**Approved**: yes

**Decision**: the login allow-list's emails are owned by the sign-up list, and the client-auth form carries only the "Only listed people" switch, sending the list's emails only when the switch turns on and `null` when it turns off.
**Rationale**: each sign-up entry carries a role and a set as well as an address, and the backend keeps the entries equal to whatever list is written. A second editor for the same emails inside the form could erase entries or disagree with the list, so one list is edited in one place and the form's dirty check compares the switch alone.
**Approved**: pending

**Decision**: the product roles pane mounts the Teams roles editor on the ecosystem target and adds only the per-role holder list through the editor's footer seam, rather than a roles editor of its own.
**Rationale**: a product's roles and a workspace's are the same kind of thing, and one editor means they cannot drift. What a workspace has and a product does not is the holder list, so that is the only piece written here, and it offers only the realm's product users.
**Approved**: pending

**Decision**: the gate resolves the workspace's default ecosystem once, above the panes, and each pane reads a missing `ecosystemId` as "No product selected." rather than doing its own resolution.
**Rationale**: a pane that rendered after a failed resolution would show an empty ecosystem as if it were a real answer, and a plain org member would discover the same refusal separately in every pane. Resolving once, and explaining once, keeps the wording and the failure handling in one place.
**Approved**: pending

