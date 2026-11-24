
### Package and exports

- **package-name**: The package MUST be named `@adh-sdk/jobs` and live in the web SDK's features folder
  beside the personas package, laid out the same way.
- **package-exports**: The package `exports` map MUST expose `.`, `./sources.css` and `./topics`. `.` and
  `./topics` each carry `types`, a `development` condition resolving to source, and `import` resolving
  to the built output.
- **topics-subpath-plain-data**: `./topics` MUST resolve to a module that holds only plain data (no
  React and no `use client`), so a server component such as a site's console layout can import the
  topic sets.
- **sources-css**: `sources.css` MUST register the package's own `src` and `dist` files as Tailwind
  sources, and MUST chain the `sources.css` of each dependency whose components the package mounts.
- **pane-exports**: The barrel MUST export `JobsPane`, `JobPane`, `JobRunPane`, `JobTemplatesPane`,
  `JobTemplatePane`, `JobEnvironmentsPane` and `JobStatusPane`, with each pane's props type.
- **topic-exports**: The barrel and `./topics` MUST both export `jobsTopics` and
  `jobsProductAdminTopics`.

### Data client

- **data-module**: The data client MUST live in `@adh-sdk/data` as its own domain folder, `jobs/`, with
  `jobs.ts` (the calls), `wire.ts` (the wire shapes) and `mappers.ts`. It is reached through a `./jobs`
  subpath in the data package's `exports`, shaped like the other domain subpaths, and never through the
  data package's root.
- **wire-from-api-types**: The wire shapes MUST be derived from `@adh-sdk/adh-api-types` once the `/jobs`
  routes are in the backend's `/v1` document. Until then (design call C18 keeps every `/jobs` route out of
  `/v1` this phase), `wire.ts` MUST restate, by hand, the camelCase shapes the unversioned routes answer,
  with the backend's `openapi.json` as its reference, and MUST say so in its header. The `Job*` components
  `@adh-sdk/adh-api-types` already carries are the `/v1` projection (snake_case, unix-second times) and
  MUST NOT be used for these routes.
- **unversioned-base**: Until the routes move into `/v1`, every call MUST go to `/api/jobs/...` (the site's
  rewrite to the backend's unversioned routes). Authoring and status calls MUST name the ecosystem as
  `?ecosystem=`; owner calls MUST pass `?workspace=<slug>` only when acting for an organization.
- **mappers-own-the-wire**: Every call MUST return camelCase domain shapes, and `mappers.ts` MUST be the
  one place that reads the wire. It fills every nullable bag (lists `[]`, objects `{}`, usage zeroes) and
  narrows every status to its union, so a pane reads a row without a guard. A step run's `stepId` and
  `name` stay null when the run has none, and its missing `kind` reads `""`.
- **route-coverage**: The client MUST offer one call per `/jobs` route the panes use:
  - authoring: templates (list, create, read, update, publish, retire), a version read, and the offers
    write with a body of `{ setIds }`;
  - owning: the catalog, jobs (list, create, read, update, delete), a job's pinned version (read,
    `/jobs/instances/{id}/version`), a manual run, triggers (list,
    create, update, delete), runs (list, read, retry, cancel), and environments (list, create, delete,
    mint token);
  - the product admin's run status read.
- **run-stream**: The client MUST offer a subscription to a run's server-sent event stream that hands
  each event to a callback and returns a function that closes the stream. The server closes the stream
  after 60 seconds; the subscription MUST reconnect then, and MUST fall back to polling the run read while
  the stream cannot open. Once a run arrives `succeeded`, `failed` or `cancelled`, the subscription MUST
  hand it to the callback and then close for good, so a finished run never becomes a reconnect loop.
- **runs-query**: The runs list MUST accept `instanceId`, `status` and `before`, and MUST return the runs
  newest first, as the route answers them.
- **once-shown-secrets**: A trigger create that returns an inbound secret, and an environment token mint,
  MUST hand the raw value to the caller once in the call's result. The client MUST NOT cache or store it.

### Topics

- **jobs-topics**: `jobsTopics` MUST list the hub workspace's three Jobs topics in this order: Jobs
  (segment `jobs`), Templates (segment `jobs/templates`) and Environments (segment `jobs/environments`).
  Each entry is `{ id, label, href }`, and its `href` is the segment the host prefixes with the
  workspace.
- **jobs-product-admin-topics**: `jobsProductAdminTopics` MUST list the product admin site's two Jobs
  topics in this order: Status (`/jobs`) and Templates (`/jobs/templates`). Each entry is
  `{ id, label, href }`, and its `href` is a page route of the product admin site.
- **topic-ids-unique**: The ids within each topic set MUST be unique.

### JobsPane

- **jobs-side-prop**: `JobsPane` MUST take `side: "customer" | "account"`, as the support access pane takes
  its side. `customer` is a product's customer. `account` is a hub user or an organization member in a
  workspace.
- **jobs-list**: The pane MUST list the caller's jobs with each job's name, its template (or "Custom"
  for inline steps), its status (`active`, `paused` or `archived`) and its last run's status.
- **jobs-catalog**: The pane MUST show the catalog of templates offered to the caller, at their latest
  versions, and creating a job from a catalog entry MUST create it from that template version.
- **jobs-customer-catalog-only**: On the `customer` side the pane MUST offer job creation only from the
  catalog. It MUST NOT offer inline steps or links to template authoring.
- **jobs-create-in-modal**: Creating a job MUST happen in a modal that asks for a name and the
  template's declared inputs, and MUST then open the created job. It is never a blank editor.
- **jobs-empty**: With no jobs the pane MUST say so and point to the catalog. With an empty catalog it MUST
  say that no templates are offered.

### JobPane

- **job-sections**: `JobPane` MUST show the job's inputs, its environment, its triggers, its
  notifications and its runs.
- **job-inputs-declared**: The inputs editor MUST offer exactly the inputs that the job's template version
  declares. A job with inline steps edits its steps instead.
- **job-inputs-pinned-version**: The catalog holds only each template's latest version, so the editor MUST
  take a template job's inputs and defaults from the job's pinned-version read, never from the catalog. It
  MUST say which version the job runs, and its inputs MUST be editable against that version (the backend
  checks a save against the same version). While that read is pending or has failed (`template_missing`
  when the version is no longer in the job's ecosystem), the pane MUST show no input fields, MUST report
  the failure, and a save MUST NOT send `inputs`.
- **job-environment-choice**: The environment choice MUST be "Hub" (no environment) or one of the
  owner's environments. A save the backend refuses with `step_needs_hub` or `step_needs_machine` MUST
  show which step needs which.
- **job-triggers**: The triggers list MUST show each trigger's kind (`schedule`, `event` or `inbound`), and
  whether it is enabled. A schedule shows its cron expression and time zone. A refusal with
  `interval_too_short` MUST be shown beside the schedule.
- **inbound-secret-once**: When an inbound trigger is created, the pane MUST show its secret once with a
  copy button. Closing it before copying MUST ask for confirmation, as a worker token's reveal does.
- **job-run-now**: The pane MUST offer "Run now", which starts a manual run and opens the returned run.
- **job-notifications**: The notifications editor MUST choose when to notify (failed, succeeded) and
  through which channels (email, SMS, hub). It MUST show what the engine resolves: the job's own notify,
  else its pinned template version's defaults (from the pinned-version read), else failures by email. A save MUST send `options.notify`
  only when the owner changed a notification choice, so saving another setting never replaces the
  version's defaults.
- **job-runs-list**: The job's runs MUST be listed newest first with a "Load more" that passes `before`.
  Every loaded page MUST be held in one paged query, so a refresh (after "Run now") reads again from the
  newest run and a new run appears at the top.
- **job-delete-archives**: Delete MUST ask for confirmation and MUST say that the job is archived and
  its runs are kept.

### JobRunPane

- **run-steps**: `JobRunPane` MUST list the run's step runs in order, each with its name, kind and status
  (`pending`, `running`, `succeeded`, `failed`, `skipped` or `cancelled`), and with its output, log and
  usage when it has them. The name MUST be the step run's own `name`, which the backend takes from the
  run's frozen steps, for inline and template jobs alike. A step run with no name MUST read "Step N" (its
  position, from 1) with its step id beside it rather than showing the bare id as a name.
- **run-live**: While the run is `queued` or `running`, the pane MUST follow it through the run stream and
  MUST close the stream when the run ends or the pane unmounts.
- **run-model-unavailable**: A step that failed with `error_code` `model_unavailable` MUST read "The model
  was switched off" rather than the provider's message.
- **run-truncated**: An output stored with `truncated: true` MUST say it was cut short.
- **run-retry**: A `failed` run MUST offer Retry, which retries the failed step and keeps the earlier
  outputs.
- **run-cancel**: A `queued` or `running` run MUST offer Cancel, behind a confirmation.

### JobTemplatesPane and JobTemplatePane

- **templates-list**: `JobTemplatesPane` MUST list the ecosystem's templates with each one's name, status
  (`draft`, `published` or `retired`), latest version and number of offering sets.
- **template-create-in-modal**: Creating a template MUST happen in a modal and MUST open the new draft.
- **template-step-editors**: `JobTemplatePane` MUST edit the draft's steps as an ordered list, with one
  editor per step kind (`ai`, `script`, `action`, `webhook`, `notify` and `wait`). Every step edits its
  `id`, `name`, `onError` and `maxAttempts`.
- **template-ai-model**: The `ai` step editor MUST choose its model as either a connection from AI Settings
  with one of its available models, or the environment's own model (`local` or `claude-code`).
- **template-inputs**: The pane MUST edit the template's declared inputs.
- **template-publish**: Publish MUST send the draft to the publish route and show the new version, or show
  the backend's validation errors beside the steps they name. Errors on the draft's defaults, which name no
  step, MUST be listed as defaults problems rather than dropped.
- **template-offers**: The offers editor MUST choose the sets that offer the template and write them with
  the offers route. A refusal because the version holds a script step MUST be shown.
- **template-retire**: Retire MUST ask for confirmation and MUST say that existing jobs keep running their
  version.

### JobEnvironmentsPane

- **environments-list**: `JobEnvironmentsPane` MUST list the owner's environments with each one's name,
  its reported capabilities and when it was last seen, or "Never".
- **environment-token-once**: Creating an environment, and minting a new token, MUST show the `jenv_`
  token once with a copy button. Minting MUST first say that the old token stops working.
- **environment-delete**: Delete MUST ask for confirmation and MUST say that jobs using the environment
  fall back to the hub.

### JobStatusPane

- **status-table**: `JobStatusPane` MUST show the product's customer runs as a table of job name,
  template, owner, status, error code, the first part of the error, and the times, read through the
  status route, newest first, with a "Load more" that passes `before`. A "Load more" that fails MUST be
  reported under the rows already shown, never in their place.
- **status-no-content**: The pane MUST NOT show or request a run's inputs, steps, outputs or logs.

### Shared behavior

- **read-failure-shown**: Each pane MUST show a failed read, and MUST report it with the context feature
  `jobs` and the step that failed.
- **switch-off-404**: A `404` from a `/jobs` route while the feature's switch is off MUST read as the feature
  being unavailable, not as a missing record.
- **host-navigation**: Each pane MUST render its own view and MUST NOT navigate on its own. It hands the
  host the id to open through a callback (`onOpenJob`, `onOpenRun`, `onOpenTemplate`, `onOpenTemplates`,
  `onDeleted`), and the host turns that into a route. Owner panes take an optional `workspace` slug and pass
  it to every call.

### Registration outside the package

- **jobs-reserved-handle-word**: `RESERVED_HANDLE_WORDS` in `@adh-sdk/adh` (`site/reservedSlugs.ts`) MUST contain `jobs`, in its alphabetical place (it is read through `reservedWorkspaceSlugs()`, the package's one accessor for that constant), so no workspace is ever given the handle the hub serves as a feature segment. The registry side (the `jobs` hub segment, the route lines and the universal reserved slug) is specified by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae), and the `/jobs` menu icon by [adhsdk.recipe.adh.sites.site-menu](cookbook:f2d56415-ac36-4a27-bee5-b447c4186513).

