
**Decision**: Return null (render nothing) rather than an empty container when a value is empty, for every type except email and phone (see **empty-email-or-phone-renders-empty-span**).
**Rationale**: An empty profile with missing pictures and unfilled fields reads better than one with visible placeholder UI. Absence of data is cleaner than attempting to gracefully degrade rendering.
**Approved**: pending

**Decision**: Render email and phone as plain text, never as `mailto:`/`tel:` links (see **email-as-text**, **phone-as-text**).
**Rationale**: Whether the value reaches the client at all is a visibility decision made server-side — these types start private, so publishing one is a choice. What a published value becomes in the markup is a separate, client-side question, and the answer is plain text: a linkified address is the one a scraper finds by selector rather than by parsing prose.
**Approved**: pending

**Decision**: Render markdown and textarea as pre-wrapped plain text, never as HTML (see **markdown-as-text**, **textarea-as-text**).
**Rationale**: The component runs on untrusted sites the registry does not control, and safe markdown-to-HTML conversion cannot be guaranteed in that context, so the conservative choice is to render all markup as literal text.
**Approved**: pending

**Decision**: Hardcode the DELIVERY_LABEL mapping in the component rather than accepting it as a prop (see **delivery-label-lookup**).
**Rationale**: It is a fixed enumeration tied to one registry field's semantics ("delivery mode"), not a generic labeling mechanism — a semantic transformation specific to this component's domain rather than a configuration point. The strings it produces ("In person", "Virtual", "In person or virtual") are still user-facing text, so they are catalogued in the Localization table like any other user-facing string this component renders.
**Approved**: pending

