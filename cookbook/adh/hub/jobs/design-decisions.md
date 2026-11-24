
**Decision**: The data client is its own `jobs/` domain in `@adh-sdk/data`, behind a `./jobs` subpath.
**Rationale**: Per the phase 9 design, each data domain has its own subpath and the root re-exports
none, so a pane imports only the domain it uses.
**Approved**: pending

**Decision**: The topic sets live behind a separate `./topics` subpath of plain data.
**Rationale**: As in the product admin package, the barrel carries `use client`, and a site's console
layout is a server component that must import the topics without it.
**Approved**: pending

**Decision**: `JobsPane` takes a `side` prop instead of being two panes.
**Rationale**: Per the design, customer jobs are a subset of developer jobs, so one pane serves both and
the customer side drops inline steps and authoring, as the support access pane's side does ([adhsdk.ingredient.adh.hub.support.support-panes](cookbook:2eff6ca4-5479-44b3-8636-04e455009a10)).
**Approved**: pending

**Decision**: `JobStatusPane` reads only the status aggregate and shows no content.
**Rationale**: Per the design (call C16), a product admin sees run status but reading inputs, outputs or
logs needs a support grant, because the runs are the customer's content.
**Approved**: pending

**Decision**: Creating a job, a template or an environment happens in a modal, never a blank editor.
**Rationale**: The `must-create-in-modal` rule of [adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8) applies, and the created row then opens.
**Approved**: pending

