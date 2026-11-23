
### Package and exports

- **package-name**: The package MUST be named `@adh-sdk/ai-settings` and live beside the personas
  package in the web SDK's features folder, laid out the same way.
- **package-exports**: The package `exports` map MUST expose `.` (with `types`, a `development`
  condition resolving to source, and `import` resolving to the built output) and `./sources.css`.
- **sources-css**: `sources.css` MUST register the package's own `src` and `dist` files as Tailwind
  sources, and MUST chain the `sources.css` of each dependency whose components the package mounts, so
  a host adds one import line.
- **moved-with-history**: `ServicesSection` and `useUserServices` MUST be moved from the personas
  package into this one, not copied, so file history follows.
- **ai-settings-section**: The package MUST export `AiSettingsSection`, which MUST render
  `ServicesSection` with the title "AI Settings".
- **services-section-export**: The package MUST export `ServicesSection`, `useUserServices` and
  `PERSONA_SERVICES_CACHE_KEY`.
- **personas-reexport**: The personas package MUST depend on this package and MUST re-export
  `ServicesSection`, `useUserServices` and `PERSONA_SERVICES_CACHE_KEY` from its barrel as the same
  objects, so a host that imports them from personas keeps working until Cleanup removes the
  re-exports.
- **personas-section-import**: `PersonasSection` MUST import these three from this package.

### The services cache

- **cache-key-kept**: `PERSONA_SERVICES_CACHE_KEY` MUST keep its name and the value
  `"persona-services"`, so a caller that writes services without this hook (the admin config-set
  services hook) still reaches the same cache entry.
- **one-cache-entry**: `useUserServices` MUST read the caller's services through one cached list
  resource, so the services pane and the persona editor's service picker share one entry and one
  invalidation.
- **services-read-failure**: A failed read in `useUserServices` MUST be reported with the context
  feature `services` and step `list` and then rethrown, because the list is the surface and the panes
  show the failure.
- **no-double-report**: `useUserServices` MUST turn off the list resource's own error reporting, so
  one failure is reported once.
- **fetcher-identity**: The fetcher passed to the list resource MUST be a module-scope function, since
  a new function identity means the scope changed and the list is read again.

### The services section

- **url-or-internal-selection**: When `urlSelection` is passed, the open service MUST come from
  `urlSelection.serviceId` and choosing or clearing a service MUST call `onSelectService` (with `null`
  to clear). When it is omitted, selection MUST be internal state, so a service opens in place.
- **default-title**: The rail level heading MUST be the `title` prop, defaulting to "Persona Services".
- **rail-items**: Each service MUST appear as a rail row labelled with its name, subtitled with its
  provider kind and carrying a boxes icon marked decorative.
- **rail-empty-label**: With no services the rail MUST say "No services yet."
- **rail-busy**: The rail heading MUST show a busy indicator while a read is in flight, including the
  re-read behind a cached paint.
- **new-service-button**: The rail MUST offer a "New Service" action that opens the create modal.
- **loading-state**: While the list is null and there is no error, the pane MUST show "Loading…".
- **read-failure-shown**: When the read fails, the failure MUST be shown. Beside listed rows it rides
  inside the rail's overview hint (the pane's children are hidden then); with no rows it renders in the
  pane.
- **nothing-open**: With no open service, or an id that matches no loaded row, the pane MUST show the
  frame's select hint (noun "service") and no editor.
- **editor-keyed-by-service**: The editor MUST be keyed by the open service's id, so each service gets
  a fresh editor and its draft is seeded once.
- **rail-host-dual-mode**: Under a rail host the section MUST publish its service level into the host's
  merged stack and render only the open service's pane as the leaf. With no rail host it MUST render
  its own hierarchical detail view with the breadcrumb hidden.
- **refresh-after-write**: After a service is saved, created, deleted, connected or has its models
  refreshed, the section MUST re-read the list, and a failed re-read MUST NOT surface as an unhandled
  rejection (it reaches the screen as the read error).
- **after-save-reselect**: After a save, connect or refresh the section MUST select the same service
  id; after a delete it MUST select none.

### Creating a service

- **create-in-modal**: Creating a service MUST happen in a modal titled "New service", labelled "New
  service" for assistive technology, never as a blank editor leaf.
- **created-selected**: When a service is created, the modal MUST close, the new service MUST be
  selected so its editor opens, and the list MUST be re-read.
- **create-payload**: The create call MUST send the trimmed name, the provider kind and the trimmed base
  URL, plus `templateId` only when a template was chosen, `apiKey` only when one was typed, and
  `connectionSpec` only when the template prompts for headers.
- **blank-draft-validation**: Create MUST be refused with "A name is required." for a blank name, "Select
  a provider." when no provider is chosen, and "A base URL is required." for a blank base URL, in that
  order. The modal's Save MUST be enabled once the form holds any input, and pressing it runs this check.
- **unfilled-url-vars**: Create MUST be refused with "Fill in all the URL fields." while the base URL
  still holds a `{name}` token.
- **unfilled-header-vars**: Create MUST be refused with "Fill in all the header fields." while any
  prompted header has a blank value.
- **template-catalog-cached**: The template catalog MUST be read through a cached list resource keyed
  `persona-service-templates`, so reopening the modal shows the picker already filled.
- **template-failure-degrades**: A failed template read MUST be reported with feature `services` and
  step `templates` and MUST be answered with an empty catalog, so a service can still be typed in by
  hand.
- **template-picker-shown**: The "Start from a template" group MUST be shown only when the catalog is
  not empty, with a first option "Custom (no template)".
- **template-label**: A template's label MUST be its name followed by its non-chat modalities joined by
  `/` in parentheses; a template whose modalities are null, omitted or only chat has no suffix.
- **template-prefill**: Choosing a template MUST fill the name, provider kind and base URL from it and
  remember the template id and its full connection spec.
- **template-url-vars**: When the template declares URL variables, the form MUST show one input per
  variable (label, else name; hint "e.g. <example>") and a read-only Base URL field with the hint "Filled
  in from the values above." that substitutes each filled value into the pattern and leaves an unfilled
  `{name}` token in place.
- **template-header-vars**: When the template declares header variables, the form MUST show one input
  per header (label, else header name), masked when the variable is secret.
- **template-spec-on-create**: With header variables, the create call MUST send the template's whole
  connection spec verbatim with the collected non-blank header values as its extra headers, and
  MUST NOT forward the template's own static extra headers; with none, it MUST send no connection spec.
- **auth-hint**: A template whose auth is not bearer MUST show a one-line hint: "Authenticates via
  the" then the header name in backticks then "header." for header auth, "Uses AWS SigV4 signing", a dash, then "not yet supported by this client." for sigv4 and "Uses OAuth", a dash, then
  "not yet supported by this client." for oauth2; a bearer or missing auth MUST show none.
- **informational-templates**: A template that names `availableVia` MUST NOT appear in the picker. It
  MUST render as a read-only card under "No first-party API" with its note.
- **use-gateway-button**: An informational card MUST show a "Use <name>" button for each named gateway
  that resolves to a connectable template, applying it on press, and MUST show no button for a name that
  resolves to another informational template or to nothing.
- **deselect-template**: Choosing "Custom (no template)" MUST clear the template id, URL and header
  prompts, template spec and auth hint, keeping the name, provider, base URL and API key typed so far.
- **provider-choices**: The provider choices MUST be OpenAI, Anthropic and Google Gemini, behind a
  "Select a provider" placeholder.
- **create-focus**: The create modal MUST focus its Name field on open.

### The service editor

- **editor-fields**: The editor MUST show Name, Provider (disabled, hint "Cannot change after
  creation."), Base URL and API key, seeded from the service; the API key input MUST start empty.
- **api-key-hint**: When the service already has a key, the API key field MUST read "Leave blank to keep
  the existing key." with the placeholder "•••• set"; otherwise the placeholder MUST be "sk-…".
- **save-gate**: Save MUST be disabled until the draft differs from what was loaded and the required
  fields are filled; it MUST start disabled for an unmodified service.
- **save-blocked-reason**: When the draft is dirty and a required field is blank, the bar MUST say why
  ("A name is required.", "Select a provider.", "A base URL is required.") as a status message; it MUST
  stay silent for an untouched, already-blank service.
- **save-payload**: Save MUST send the trimmed name and trimmed base URL, plus `apiKey` only when one was
  typed.
- **save-recovery**: After a successful save the draft MUST become the new baseline, so Save disables
  again, and the saving state MUST clear.
- **save-failure**: A failed save MUST be reported (feature `services`, step `save`) and MUST show the
  error message, or "Failed to save service." when the error carries none.
- **delete-confirmation**: Delete MUST first ask for confirmation naming the service ("Delete service
  "<name>"? This cannot be undone."), and MUST do nothing when it is declined.
- **delete-failure**: A failed delete MUST be reported (step `delete`), MUST show the error message, or
  "Failed to delete service.", and MUST leave the editor usable.
- **dirty-exit-guard**: While the draft is dirty the editor MUST publish an exit guard reporting dirty to
  the rail host, and MUST withdraw it when the draft is clean again (reverted or saved); it MUST publish
  nothing while the service is unmodified.
- **connect-button**: The Connection group MUST offer a Connect button reading "Connecting…" and
  disabled while the call runs.
- **connect-result**: After connecting, the editor MUST adopt the returned service. A `failed` status
  with an error MUST show that error; a `connected` status MUST show "Connected successfully."
- **last-connected**: When the service has a last-connected time, the Connection group MUST show it as
  "Last: <date>".
- **refresh-button**: The Models group MUST offer a Refresh button reading "Refreshing…" and disabled
  while the call runs, and on success MUST adopt the returned service.
- **fetched-at**: When the models were fetched, the Models group MUST show "Fetched: <date>".
- **refresh-models-failure**: NEEDS REVIEW: Not implemented in source. A failed Connect or Refresh is only reported (steps `connect` and `refreshModels`) and shows no message of its own; the screen needs a decision on whether a failed refresh should say so, settled by the owner of the screen's error design.
- **api-link**: The editor's button bar MUST carry the service API entry for path `/v1/ai_services/{id}`
  titled "Service API".

### The models table

- **table-empty**: With no models the table MUST be replaced by the text "No models yet", a dash, then "Connect or Refresh."
- **table-columns**: The table MUST keep the columns Model, Family, Context, Max out, $/1M in, $/1M
  out and Caps, in that order, and MUST gain an Available column.
- **models-from-service-row**: The table MUST render the models carried by the service row, not a live
  model route.
- **model-name**: A model's first column MUST show its display name, else its id.
- **dash-for-missing**: Family, Context, Max out and both prices MUST show the dash glyph when absent.
- **number-format**: Context and Max out MUST show a value of 1,000,000 or more as millions with one
  decimal and "M", a value of 1,000 or more as thousands rounded to a whole number with "K", and a
  smaller value as is.
- **price-format**: A price MUST show a dollar sign and two decimals.
- **capability-chips**: Caps MUST show a chip for each of tools, vision and thinking the model supports,
  and the dash glyph when it supports none.
- **available-checkbox**: Each row MUST show an Available checkbox, ticked exactly when the model's
  `available` is true; a model with no `available` value MUST read as available.
- **available-change**: Changing the checkbox MUST call the data client's `setModelAvailability` with the
  service id, the model and the new checked value, then revalidate the services cache
  (`PERSONA_SERVICES_CACHE_KEY`).
- **no-longer-offered**: A model whose `offered` is false MUST show "No longer offered" and an unticked
  checkbox. A model with no `offered` value MUST read as offered.
- **model-key**: Rows MUST be keyed by model id.

### The data contract this screen relies on

- **model-item-shape**: Each model item the screen reads MUST carry `available` (boolean, true when the
  wire omits it) and `offered` (boolean, true when the wire omits it), in addition to its existing
  fields.
- **set-availability-call**: The data client MUST expose `services.setModelAvailability(id, model,
  available)` beside `refreshModels`, calling `POST /api/v1/ai_services/{id}/model_availability` (the v1
  route `/v1/ai_services/{id}/model_availability`) with the body
  `{ model, available }` and reading the answer, the updated service, with the service decoder.
- **disabled-names-appended**: Names the provider no longer lists but which remain switched off MUST be
  appended to a service's model list with `offered` false and `available` false.

### Dependent screens

- **persona-select-available-only**: The persona editor's model select MUST list only available models.
- **persona-keeps-saved-model**: A persona whose saved model is switched off MUST show that model as the
  current value labelled "(not available)" with an inline note, so saving other fields does not change
  the model.
- **persona-service-change-reset**: Changing the persona's service MUST still reset its model, as before.

### Registry and routing

- **segment-ai-settings**: The hub registry's extra feature segments MUST include `ai-settings`; the
  generated routes, the reserved slugs and the menu icons MUST each gain an `ai-settings` entry.
- **redirect-only-segments**: The `llm-providers` and `persona-services` segments MUST stay as
  redirect-only segments until Cleanup removes them.

