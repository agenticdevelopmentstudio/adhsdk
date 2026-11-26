
Jobs is the hub feature for scheduled and triggered work: AI steps, integration actions, webhooks,
notifications and waits, run on the hub or on a machine the owner runs. This ingredient is the web
package `@adh-sdk/jobs` and its data client, the `jobs` domain of `@adh-sdk/data` reached through the
`./jobs` subpath. It was written in phase 9, before the code, as the shared design. Both now exist: the
data client in `packages/web/packages/data/src/jobs/` and the package in
`packages/web/packages/features/jobs/`.

The package holds seven panes:

- `JobsPane` lists the owner's jobs and the catalog of templates offered to them. It takes a `side` prop,
  as the support access pane does ([adhsdk.ingredient.adh.hub.support.support-panes](cookbook:2eff6ca4-5479-44b3-8636-04e455009a10)).
- `JobPane` shows and edits one job: its inputs, environment, triggers, notifications and runs.
- `JobRunPane` shows one run: its steps with their status, output, log and usage. It also offers retry
  and cancel.
- `JobTemplatesPane` and `JobTemplatePane` are where templates are written: a step list with an editor
  per step kind, the declared inputs, publishing, and the sets that offer the template.
- `JobEnvironmentsPane` lists the owner's machines, their tokens and when each was last seen.
- `JobStatusPane` is the product admin's run status table. It shows no content.

The package also exports two topic sets: `jobsTopics` for the hub workspace and
`jobsProductAdminTopics` for the product admin console's Jobs pages, under `/admin`.

The model the panes show is the phase 9 design's:

- A **template** is a named, versioned recipe for a job.
- A **version** is one published, immutable copy of a template's steps.
- An **offer** is a template that a set makes available to its customers.
- A **job** is a template version (or, for a manager, inline steps) made concrete for one owner.
- A **trigger** is what starts a run.
- A **run** is one execution of a job, and a **step run** is one step of a run.
- An **environment** is a machine the owner runs.

The routes the client calls are the backend's `/jobs` routes. The `jobs` hub segment and the
`/admin/jobs` and `/admin/jobs/templates` pages of the product admin console are specified by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae). The Jobs row on
the product admin rail is specified by [adhsdk.ingredient.adh.hub.product-admin.product-admin-site](cookbook:2cb51edd-84c5-448a-a5dc-134d3f8b6c1c), and the menu icon by [adhsdk.recipe.adh.sites.site-menu](cookbook:f2d56415-ac36-4a27-bee5-b447c4186513). The feature requires the
AI Settings feature ([adhsdk.ingredient.adh.hub.ai-settings](cookbook:5fdf4ce9-cb7e-4490-a6d6-066690ef07ca)), whose connections and models an AI step names.

