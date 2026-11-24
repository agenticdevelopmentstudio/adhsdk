---
id: 0bcb370d-a44f-48a8-a313-0266c2f86e51
title: "Jobs"
type: ingredient
version: 1.1.0
status: draft
language: en
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Jobs feature package and its data client: the owner's jobs and catalog, a job, a run, template authoring, machine environments and the product admin's run status, plus the hub and product admin topic sets."
platforms:
  - typescript
  - web
tags:
  - hub
  - jobs
  - workflows
  - scheduling
  - data-client
depends-on:
  - 5fdf4ce9-cb7e-4490-a6d6-066690ef07ca
related:
  - 9069ccf9-0357-4311-9671-91ee2793adae
  - 2eff6ca4-5479-44b3-8636-04e455009a10
  - 2cb51edd-84c5-448a-a5dc-134d3f8b6c1c
  - 0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8
  - f2d56415-ac36-4a27-bee5-b447c4186513
references: []
approved-by: ""
approved-date: ""
---

# Jobs

## Overview

Jobs is the hub feature for scheduled and triggered work: AI steps, integration actions, webhooks,
notifications and waits, run on the hub or on a machine the owner runs. This ingredient is the web
package `@adh-sdk/jobs` and its data client, the `jobs` domain of `@adh-sdk/data` reached through the
`./jobs` subpath. It was written in phase 9, before the code, as the shared design. The data client now exists
(`packages/web/packages/data/src/jobs/`); the package does not yet.

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
`jobsProductAdminTopics` for the product admin site's Jobs pages.

The model the panes show is the phase 9 design's:

- A **template** is a named, versioned recipe for a job.
- A **version** is one published, immutable copy of a template's steps.
- An **offer** is a template that a set makes available to its customers.
- A **job** is a template version (or, for a manager, inline steps) made concrete for one owner.
- A **trigger** is what starts a run.
- A **run** is one execution of a job, and a **step run** is one step of a run.
- An **environment** is a machine the owner runs.

The routes the client calls are the backend's `/jobs` routes. The `jobs` hub segment and the
`/jobs` and `/jobs/templates` pages of the product admin site are specified by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae). The Jobs row on
the product admin rail is specified by [adhsdk.ingredient.adh.hub.product-admin.product-admin-site](cookbook:2cb51edd-84c5-448a-a5dc-134d3f8b6c1c), and the menu icon by [adhsdk.recipe.adh.sites.site-menu](cookbook:f2d56415-ac36-4a27-bee5-b447c4186513). The feature requires the
AI Settings feature ([adhsdk.ingredient.adh.hub.ai-settings](cookbook:5fdf4ce9-cb7e-4490-a6d6-066690ef07ca)), whose connections and models an AI step names.

## Behavioral Requirements

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
  narrows every status to its union, so a pane reads a row without a guard.
- **route-coverage**: The client MUST offer one call per `/jobs` route the panes use:
  - authoring: templates (list, create, read, update, publish, retire), a version read, and the offers
    write with a body of `{ setIds }`;
  - owning: the catalog, jobs (list, create, read, update, delete), a manual run, triggers (list,
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
  through which channels (email, SMS, hub). The default is failures by email.
- **job-delete-archives**: Delete MUST ask for confirmation and MUST say that the job is archived and
  its runs are kept.

### JobRunPane

- **run-steps**: `JobRunPane` MUST list the run's step runs in order, each with its name, kind and status
  (`pending`, `running`, `succeeded`, `failed`, `skipped` or `cancelled`), and with its output, log and
  usage when it has them.
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
  the backend's validation errors beside the steps they name.
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
  status route, newest first, with a "Load more" that passes `before`.
- **status-no-content**: The pane MUST NOT show or request a run's inputs, steps, outputs or logs.

### Shared behavior

- **read-failure-shown**: Each pane MUST show a failed read, and MUST report it with the context feature
  `jobs` and the step that failed.
- **switch-off-404**: A `404` from a `/jobs` route while the feature's switch is off MUST read as the feature
  being unavailable, not as a missing record.
- **rail-host-dual-mode**: Each pane that owns a level MUST publish it into a rail host when one exists and
  render its own hierarchical detail view when none does.

### Registration outside the package

- **jobs-reserved-handle-word**: `RESERVED_HANDLE_WORDS` in `@adh-sdk/adh` (`site/reservedSlugs.ts`) MUST contain `jobs`, in its alphabetical place (it is read through `reservedWorkspaceSlugs()`, the package's one accessor for that constant), so no workspace is ever given the handle the hub serves as a feature segment. The registry side (the `jobs` hub segment, the route lines and the universal reserved slug) is specified by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae), and the `/jobs` menu icon by [adhsdk.recipe.adh.sites.site-menu](cookbook:f2d56415-ac36-4a27-bee5-b447c4186513).

## Appearance

- **Layout**: Every pane is a rail of rows beside a detail pane, built from the shared hierarchical
  detail view, field groups and button bar, so Jobs reads like the other hub features.
- **Status**: A run's and a step's status is shown as a text badge (Succeeded, Failed, Running and so on).
  Color is secondary to the text.
- **Tables**: The run status table and the environments list use the shared editable list's columns,
  sorting and search.
- **Code fields**: A script body, a cron expression, a JSON input and a step output are shown in a
  monospace field.
- **Secrets**: An inbound secret and an environment token are shown in a read-only monospace input with a
  copy button.

## States

| State | Appearance change |
|-------|------------------|
| Loading | A pane reads "Loading…" until its first read arrives. |
| Read failed | The failure shows in the pane in the shared error text. |
| Empty | JobsPane says no jobs yet and points to the catalog; the catalog says no templates are offered; the templates and environments lists say none yet. |
| Feature unavailable | A pane whose route answers 404 with the switch off says Jobs is not available. |
| Run live | A queued or running run updates its steps as stream events arrive. |
| Run failed | The failed step shows its error, and Retry is offered. |
| Saving | A Save button reads "Saving…" and is disabled. |
| Secret shown | The reveal dialog shows the value once, with a copy button and a confirmation on close. |

## Accessibility

- **Role/trait**: The status table is a native table with header cells. Every status badge carries its
  status as text. Every error line is the shared error text with the alert role.
- **status-text-not-color**: A run's or step's status MUST be readable as text, not only as a color.
- **Keyboard**: Every control is a native input, select, button or checkbox. The step list's reordering
  MUST be reachable from the keyboard (move up and move down buttons), not only by dragging.
- **Announce state changes**: A live run's status change MUST be announced through a polite live region.
- **Labels**: Each step editor's fields MUST carry labels naming the step, so two steps' fields can be told
  apart.

## Conformance Test Vectors

These vectors come from the phase 9 design and are the tests the package's `__tests__/` and the data
client's `jobs/__tests__/` MUST carry. The data client and its tests are written; the package is not yet.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| jobs-001 | jobs-topics, topic-ids-unique | `jobsTopics` | Three entries in order: Jobs `jobs`, Templates `jobs/templates`, Environments `jobs/environments`; the ids are unique. |
| jobs-002 | jobs-product-admin-topics, topic-ids-unique | `jobsProductAdminTopics` | Two entries in order: Status `/jobs`, Templates `/jobs/templates`; the ids are unique. |
| jobs-003 | topics-subpath-plain-data | Import `@adh-sdk/jobs/topics` in a module with no React | Both topic sets load; the module imports nothing from React. |
| jobs-004 | jobs-customer-catalog-only | Render `JobsPane side="customer"` with a catalog of one template | Creation is offered from the catalog entry only; no inline-steps or template authoring action is shown. |
| jobs-005 | jobs-side-prop, jobs-catalog | Render `JobsPane side="account"` with a catalog of one template; create a job from it | The create call names that template's latest version. |
| jobs-006 | run-model-unavailable | A run whose failed step has `error_code` `model_unavailable` and a provider message | The step reads "The model was switched off"; the provider message is not the step's headline. |
| jobs-007 | run-retry, run-cancel | A `failed` run; a `running` run | The failed run offers Retry and not Cancel; the running run offers Cancel and not Retry. |
| jobs-008 | run-live | A `running` run whose stream sends a step's success, then the run's success | The step's status changes, then the stream is closed. |
| jobs-009 | status-no-content | Render `JobStatusPane` | The only read is the status route; no run read, and no inputs, outputs or logs, are requested or shown. |
| jobs-010 | mappers-own-the-wire | Map a wire run with `errorCode`, `createdAt` and step runs | The domain run carries `errorCode`, `createdAt` and camelCase step runs. |
| jobs-011 | once-shown-secrets, inbound-secret-once | Create an inbound trigger whose result carries a secret; close the reveal without copying | The secret is shown once; closing asks for confirmation; a later trigger read carries no secret. |
| jobs-012 | job-environment-choice | Save a job with an environment while the backend answers 422 `step_needs_hub` for step `summarize` | The refusal names the step `summarize` and says it needs the hub. |
| jobs-013 | jobs-reserved-handle-word | `reservedWorkspaceSlugs()` from `@adh-sdk/adh` | Contains `jobs` |

## Edge Cases

- **Null and empty input**: No jobs, no catalog, no templates and no environments each show their own empty
  text (MUST). A step run with no output shows none, not an empty box (MUST).
- **Boundary values**: An output stored at the 256 KiB cap with `truncated: true` says it was cut short
  (MUST). A step log holds at most 200 lines and is shown whole.
- **Unknown id**: A selected job, run, template or environment that matches no loaded row shows the select
  hint and never a blank pane (MUST).
- **Concurrent access**: A run that ends while its pane is open stops the stream and shows the final state
  (MUST). A cancel of a run whose step is already claimed shows the run cancelled, while that step
  finishes on the node.
- **Switch off**: Every `/jobs` route answers 404 while the feature's switch is off, and the panes read
  that as the feature being unavailable (MUST).
- **Limits**: A create or run refused for a set limit (`jobs.max_jobs`, `jobs.min_interval_minutes`) shows
  the backend's message. A run started over `jobs.monthly_runs` arrives `failed` with `error_code`
  `limit_runs`, and the run pane says why.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` (JobsPane, JobPane) | `"customer"` or `"account"` | required on JobsPane | Who the caller is. The customer side creates jobs only from the catalog. |
| `jobId` (JobPane) | string | required | The job shown. |
| `runId` (JobRunPane) | string | required | The run shown. |
| `templateId` (JobTemplatePane) | string | required | The template edited. |
| `onOpenJob`, `onOpenRun`, `onOpenTemplate` | `(id: string) => void` | omitted | Lets a host make the open row URL-driven; omitted, selection is internal state. |

## Deep Linking

The panes own no URL. The hub serves them under the workspace segment `jobs`, whose catch-all line
carries the `jobs/templates` and `jobs/environments` sub-paths, and the product admin site serves
`JobStatusPane` at `/jobs` and `JobTemplatesPane` at `/jobs/templates`. Both are specified by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae). A
host makes the open row deep-linkable through the `onOpen*` callbacks.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | Jobs, Templates, Environments, Status | Topic labels |
| n/a (literal) | Run now | Manual run action |
| n/a (literal) | Retry, Cancel | Run actions |
| n/a (literal) | Publish, Retire | Template actions |
| n/a (literal) | Hub | The no-environment choice |
| n/a (literal) | The model was switched off | A step failed with `model_unavailable` |
| n/a (literal) | Never | An environment never seen |
| n/a (literal) | Loading… | First read outstanding |

## Accessibility Options

- **Reduce Motion**: Not applicable: the panes draw no animation of their own.
- **Increase Contrast**: All colors are theme tokens.
- **Differentiate Without Color**: Satisfied by status-text-not-color: every status is text.

## Feature Flags

The panes are not gated by a flag in this package. Whether a workspace sees Jobs is decided by the
`jobs` feature in the backend's feature catalog, which requires `ai-settings`, and by the
`jobs_feature` product switch. While the switch is off every `/jobs` route answers 404, which the
panes read as the feature being unavailable.

## Analytics

Not applicable: the panes make no analytics or telemetry calls. Unexpected failures go to the shared
error reporter with the feature `jobs` and a step, which is error reporting, not analytics.

## Privacy

- **Data collected**: Job inputs, step definitions, step outputs and logs, trigger settings, and an
  environment's reported capabilities. These are the owner's content.
- **Storage**: Server side. An inbound secret and an environment token are shown once, are stored by the
  backend only as a hash, and are never read back. The client keeps lists in an in-memory cache only.
- **Product admin**: `JobStatusPane` reads only the status aggregate, which carries no inputs, steps,
  outputs or logs. Reading content needs a support grant.
- **Retention**: A backend matter; deleting a job archives it and keeps its runs.

## Logging

Not applicable: the panes contain no logging calls. Failures go to the shared reporter with the
feature `jobs` and the step, such as `list`, `catalog`, `save`, `run`, `retry`, `cancel`, `publish`,
`offers`, `environments` or `status`.

## Platform Notes

- **SwiftUI**: A `NavigationSplitView` with jobs in the sidebar and a `Form` detail. Use a `.sheet` for
  create and for the once-shown secret, with `.interactiveDismissDisabled()` until it is copied. Use a
  `Table` for the run status. Read the run stream with `URLSession.bytes(for:)` and cancel the task
  when the view disappears.
- **Compose**: A `ListDetailPaneScaffold` with a `LazyColumn` of jobs. A `ModalBottomSheet` holds create and
  the secret reveal. Collect the run stream in a `ViewModel` flow scoped to the screen, and show status as
  text in an `AssistChip`.
- **React/Web**: The source platform. The package is a client component library built from the shared
  UI blocks (hierarchical detail view, field groups, button bar, create dialog, rail host, editable
  list) and the shared list resource hook. The topic sets sit in a plain-data module behind `./topics`.
  The data client is a plain module of `authedJson` calls with an `EventSource` for the run stream.
- **AppKit / UIKit**: A split view controller with an `NSOutlineView` or `UITableView` of jobs. The status
  table is an `NSTableView`, and a sheet holds the secret reveal. Stream with a `URLSession` data task
  delegate and cancel it on `viewWillDisappear`.
- **WinUI 3**: A `NavigationView` with a `ListView` of jobs. A `ContentDialog` holds create and the secret
  reveal, with `PrimaryButtonText` "Done" and a confirmation on close. The status table is a
  `DataGrid`, and step reordering uses up and down `Button`s for keyboard reach.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/features/jobs/` | planned |
| web | `packages/web/packages/data/src/jobs/` | unverified |

## Design Decisions

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

**Decision**: The data client restates the unversioned `/jobs` wire by hand and calls `/api/jobs/...`.
**Rationale**: Per the design (call C18), no `/jobs` route is in `/v1` this phase, so the generated types
carry no `/jobs` paths, and their `Job*` components are the `/v1` projection, not what the routes answer.
Moving the routes into `/v1` later swaps `wire.ts` for aliases of the generated components and the
mappers read the snake_case, with no change to a caller.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | pending | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | pending | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | pending | Access Patterns |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | pending | Security |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | pending | Accessibility |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | pending | Performance |

Every check is `pending` because the package is not written yet. The requirements aim each one:
- `separation-of-concerns`: transport in the data client, mapping in `mappers.ts`, topics in their own
  plain-data module.
- `unit-test-coverage`: the vectors above.
- `error-response-handling`: read-failure-shown, the refusal messages and switch-off-404.
- `secure-storage`: once-shown-secrets.
- `semantic-markup`: the native status table and status-text-not-color.
- `caching-strategy`: one cached list resource per list.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-23 | Mike Fullerton | Data client written: unversioned /api/jobs wire restated by hand (call C18), run stream reconnect and stop, mappers fill nullable bags |
| 1.0.0 | 2026-11-23 | Mike Fullerton | Initial creation: the Jobs package and its data client for phase 9, written before the code |
