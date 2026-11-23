---
id: 5fdf4ce9-cb7e-4490-a6d6-066690ef07ca
title: "AI Settings"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The AI Settings screen: a workspace's AI service connections (connect, refresh models, edit, delete) and a per-model Available switch, as a rail of services beside a service editor."
platforms:
  - typescript
  - web
tags:
  - hub
  - ai-settings
  - forms
  - component
  - ui
depends-on:
  - 4af83bb1-0178-462a-b0fc-ae009b63133f
related: []
references: []
approved-by: ""
approved-date: ""
---

# AI Settings

## Overview

AI Settings is the screen where a workspace connects AI providers and chooses which of their models
it can use. It is the web package `@adh-sdk/ai-settings`. Its main export, `ServicesSection`, is a
two-part surface: a rail that lists the workspace's service connections (each labelled with its name
and subtitled with its provider kind), and a pane that edits the open one. A service is created in a
modal over the rail, never in a blank editor. The editor holds the service's fields (name, provider,
base URL, API key), a Connection group with a Connect button, and a Models group with a Refresh
button and a table of the provider's models.

The package was carved out of the personas package and keeps that package's behavior, with the phase 8
changes stated below as requirements. After phase 8 each model in the table has an Available checkbox,
ticked by default, which switches the model on or off for this workspace, and a model the provider no
longer lists but which is still switched off shows as "No longer offered". `AiSettingsSection` is
`ServicesSection` titled "AI Settings". The service list is read through `useUserServices`, one cache
entry shared with the persona editor's service picker; its key keeps the name
`PERSONA_SERVICES_CACHE_KEY` and the value `"persona-services"`. The data client, the model and service
types, and the wire shapes belong to the personas data module (see
[adhsdk.ingredient.adh.hub.personas](cookbook:4af83bb1-0178-462a-b0fc-ae009b63133f)); this recipe covers
the screen, its hook and its package layout.

## Behavioral Requirements

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

## Appearance

- **Corner radius**: The models table sits in a rounded container with a one-pixel border in the
  border token; capability chips are small rounded rectangles.
- **Padding**: Table cells are 12px by 8px; chips are 4px by 2px; the editor's body is 24px by 16px with
  16px between groups; the pane title row is 24px by 16px at the top and 8px at the bottom.
- **Font**: Table body text is the small body size; header cells are monospace at 0.7rem, uppercase,
  letter-spaced, medium weight; numeric and family cells are monospace at the extra-small size; chips
  are monospace at 0.6rem.
- **Background**: The table header row uses the second surface token at 40 percent; chips use the
  second surface token.
- **Foreground/Text**: Model names use the primary text token; family, numbers and header cells the
  muted token; the empty-caps dash the dim token; "Connected successfully." the green token.
- **Border**: One pixel in the border token around the table container, under the header row and between
  body rows; informational template cards have the same border.
- **Shadow**: None.
- **Min/Max size**: None; the pane scrolls vertically and the table fills its group's width.

All values are design tokens and utility classes in source; the component defines no literal colors.

## States

| State | Appearance change |
|-------|------------------|
| Default | The rail lists the services; the pane shows the select hint, or the open service's editor. |
| Loading | The pane reads "Loading…" until the first list arrives. |
| Fetching | A busy indicator beside the rail heading while a read or re-read is in flight. |
| Read failed | The error appears in the overview hint (rows listed) or in the pane (no rows). |
| Empty list | The rail says "No services yet." and the pane shows the select hint. |
| Dirty editor | Save is enabled once the draft is valid; a blocker message shows when a required field is blank; an exit guard is published. |
| Saving | The Save button reads as saving and the editor's fields are unchanged. |
| Connecting | The Connect button reads "Connecting…" and is disabled. |
| Connect failed | The connect error is shown under the button. |
| Connected | "Connected successfully." in green. |
| Refreshing | The Refresh button reads "Refreshing…" and is disabled. |
| No models | The table is replaced by the text "No models yet", a dash, then "Connect or Refresh." |
| Model available | The row's Available checkbox is ticked. |
| Model unavailable | The row's Available checkbox is unticked. |
| Model no longer offered | The row shows "No longer offered" and an unticked checkbox. |
| Create modal open | The "New service" modal is over the rail with its Name field focused. |
| Create refused | The modal shows the validation message under the form. |
| Disabled control | The Provider select in the editor is disabled. |

Pressed and hover states of buttons belong to the shared button component and are not defined here.

## Accessibility

- **Role/trait**: The models table is a native table with header cells; the Available control is a
  checkbox; the create modal is a modal dialog labelled "New service"; the blocker message in the
  button bar has the status role; every error line (list, save, delete, create and connect errors) is
  the shared `ErrorText` with the alert role; the rail icons are marked decorative.
- **available-checkbox-label**: NEEDS REVIEW: Not implemented in source. Neither the design nor the source says how each row's Available checkbox is named for assistive technology; a row with only a bare checkbox cannot be told apart from the next, and the screen's reviewer needs to decide on a per-model accessible name (for example the model's display name) before this is testable.
- **Keyboard**: Every control is a native input, select, button or checkbox, so it takes the platform's
  default keyboard path; the source adds no custom key handling.
- **Announce state changes**: The blocker message announces itself (status role) and every error line
  announces itself (alert role), including a failed connect status. "Connected successfully." is plain
  text with no live region.
- **Minimum tap target**: Not applicable: the sizes come from the shared button, input and checkbox
  components; this component defines none of its own.
- **Contrast**: Not determinable from source: the colors are theme tokens whose resolved values this
  component does not define.

## Conformance Test Vectors

The first eight vectors come from the named tests in `ServicesSection.test.tsx` beside the source, and
the ninth from the setup every one of them shares. The others are derived from the source's own
functions and from the phase 8 design; the plan's `ModelsTable.test.tsx` covers the Available vectors.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-settings-001 | save-gate | An open service, unmodified (test "starts disabled for an unmodified service and enables after one field edit") | Save is disabled; after typing one character into Name it is enabled. |
| ai-settings-002 | save-recovery, save-payload | Rename the service to "Renamed" and press Save (test "re-disables Save after a successful save") | The patch call receives the id `svc_1` and exactly name "Renamed" and the unchanged base URL; afterwards a button named Save exists and is disabled. |
| ai-settings-003 | save-blocked-reason | Set Name to two spaces (test "says WHY Save is blocked when a required field is cleared") | Save is disabled and the text "A name is required." is shown; before the edit it was not shown. |
| ai-settings-004 | save-blocked-reason | A service that arrives with a blank name, untouched (test "stays silent about an already-blank name the user hasn't touched") | Save is disabled and "A name is required." is not shown. |
| ai-settings-005 | dirty-exit-guard | An unmodified service under a rail host (test "registers nothing while the open service is unmodified") | No exit guard is registered. |
| ai-settings-006 | dirty-exit-guard | Type "!" into Name under a rail host (test "publishes a guard reporting dirty once the draft is edited") | One guard is registered and it reports dirty. |
| ai-settings-007 | dirty-exit-guard | Type "!" then a backspace (test "withdraws the guard when the edit is reverted") | The guard is registered after the first key and withdrawn after the second. |
| ai-settings-008 | dirty-exit-guard, save-recovery | Edit the name and Save successfully (test "withdraws the guard after a successful save") | The guard is withdrawn once the patch call resolves. |
| ai-settings-009 | url-or-internal-selection, editor-keyed-by-service | Render with `urlSelection` naming service `svc_1` and a list holding it (the setup of every test in the file) | The editor for that service opens with its Save button visible. |
| ai-settings-010 | blank-draft-validation | Press Save in the create modal with a provider chosen and the name blank, then with a name only, then with a name and provider | "A name is required.", then "Select a provider.", then "A base URL is required."; with every field empty Save is disabled. |
| ai-settings-011 | unfilled-url-vars | Template base URL `https://{region}.example.com` with the region left blank | Create is refused with "Fill in all the URL fields."; with region "eu" the Base URL reads `https://eu.example.com`. |
| ai-settings-012 | template-label | Template "Fal" with modalities `["image"]`; template "OpenAI" with modalities null; template "X" with `["chat","audio"]` | "Fal (image)"; "OpenAI"; "X (audio)". |
| ai-settings-013 | number-format | Context 1,500,000; 128,000; 900; absent | "1.5M"; "128K"; "900"; the dash glyph. |
| ai-settings-014 | price-format, dash-for-missing | Input price 3, output price absent | "$3.00" and the dash glyph. |
| ai-settings-015 | capability-chips | A model supporting tools and thinking only; a model supporting none | Chips "tools" and "thinking"; a lone dash glyph. |
| ai-settings-016 | available-checkbox | A model `{ id: "m1", available: true }`; one with `available: false`; one with no `available` | Ticked; unticked; ticked. |
| ai-settings-017 | available-change, set-availability-call | Untick the box of model `m1` on service `svc_1` | `setModelAvailability("svc_1", "m1", false)` is called and the services cache is revalidated. |
| ai-settings-018 | no-longer-offered | A model with `offered: false` and `available: false` | The row shows "No longer offered" and an unticked checkbox. |
| ai-settings-019 | table-empty | A service with an empty model list | the text "No models yet", a dash, then "Connect or Refresh." and no table. |
| ai-settings-020 | cache-key-kept, personas-reexport | Import the key from this package and from the personas package | Both are the string `"persona-services"`, and the three re-exports are the same objects. |
| ai-settings-021 | ai-settings-section | Render `AiSettingsSection` | The rail heading reads "AI Settings". |
| ai-settings-022 | services-read-failure | The list call rejects | The failure is reported with feature `services`, step `list`, and the pane shows the error rather than "Loading…". |
| ai-settings-023 | template-failure-degrades | The template call rejects while the create modal is open | The failure is reported (step `templates`), the template group is absent and the fields work by hand. |
| ai-settings-024 | persona-keeps-saved-model | A persona saved with model `m2`, which is switched off | The persona editor's select shows `m2 (not available)` with a note, and lists no other unavailable model. |
| ai-settings-025 | delete-confirmation | Press Delete and decline the confirmation | No delete call is made. |

## Edge Cases

- **Null and empty input**: A null list with no error shows "Loading…" (MUST). An empty list shows "No
  services yet." (MUST). A service with no models shows the text "No models yet", a dash, then "Connect or Refresh." (MUST). A
  model with no display name shows its id (MUST). Missing numbers show the dash glyph (MUST).
- **Boundary values**: Context or max-output of exactly 1,000 shows "1K" and exactly 1,000,000 shows
  "1.0M" (MUST). A base URL holding any `{word}` token is refused on create (MUST). A name of only
  spaces counts as blank (MUST).
- **Unknown id**: A selected id that matches no loaded service, such as one just deleted, shows the select
  hint and never a blank pane (MUST).
- **Concurrent access**: Two services panes and the persona editor share one cache entry, so a write in
  one is visible in the others once the entry is revalidated (MUST). Two people switching the same model
  at once is decided by the server's last write; the screen does no merging (not determinable from
  source).
- **Error states**: A failed list read is shown (MUST). A failed save or delete shows its message
  (MUST). A failed create keeps the modal open and shows the error message, or "Failed to create."
  (MUST). A failed template read degrades to an empty catalog (MUST). A failed connect or refresh is
  reported but shows no message of its own (see the open question on `refresh-models-failure`). A failed
  availability call has no specified user-visible state in the design, so this recipe sets none.
- **Offline or disconnected state**: The screen does no offline handling of its own. With no
  connection the list read fails and is shown as an error, and every write fails as described above;
  nothing is queued or retried (MUST NOT retry).
- **Template with both URL and header variables**: Both prompt sets render, the Base URL substitutes
  only URL values, and the header values ride in the connection spec on create (MUST).
- **Editing a service made from a template**: The editor does not re-prompt for URL or header
  variables, because they cannot be recovered from the stored URL; it edits the resolved base URL (MUST).
- **Dirty draft and object-valued fields**: The draft's URL and header value maps are compared by
  identity, so re-enabling prompts in the editor would make Save read as permanently dirty; they MUST be
  encoded as primitives first. Today the editor never renders them.
- **Provider fixed**: The provider cannot change after creation (MUST).
- **Model no longer offered**: A model switched off and then dropped by the provider stays in the list
  as "No longer offered" so it can be cleared, and ticking it back on removes its off record (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `urlSelection` | `{ serviceId?: string; onSelectService: (id: string or null) => void }` | omitted | Makes the open service URL-driven and deep-linkable; omitted, selection is internal state. |
| `title` | string | "Persona Services" for `ServicesSection`; "AI Settings" for `AiSettingsSection` | The rail level heading, for example the label a host's Settings topic uses. |
| `PERSONA_SERVICES_CACHE_KEY` | string | `"persona-services"` | The cache key of the services list, exported for callers that write services without the hook. |

## Deep Linking

Not applicable at the screen level: the component owns no URL. A host supplies `urlSelection` to make
the open service deep-linkable; the route segment is the host's (`ai-settings`, with `llm-providers`
and `persona-services` redirecting to it until Cleanup).

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | AI Settings | Rail heading of `AiSettingsSection` |
| n/a (literal) | Persona Services | Default rail heading of `ServicesSection` |
| n/a (literal) | No services yet. | Empty rail |
| n/a (literal) | New Service, New service | Rail action; create modal title |
| n/a (literal) | Loading… | First read outstanding |
| n/a (literal) | No models yet, a dash, then Connect or Refresh. | Empty models table |
| n/a (literal) | Available, No longer offered | Table column; unlisted model |
| n/a (literal) | Connect, Connecting…, Refresh, Refreshing… | Connection and Models buttons |
| n/a (literal) | Connected successfully. | Connect result |
| n/a (literal) | A name is required., Select a provider., A base URL is required. | Required-field messages |
| n/a (literal) | Fill in all the URL fields., Fill in all the header fields. | Create-only messages |
| n/a (literal) | Failed to save service., Failed to delete service. | Fallback error messages |

All strings are literals in source with no message catalog; number formatting uses fixed "K" and "M"
suffixes and a fixed dollar sign, not locale formatting.

## Accessibility Options

- **Reduce Motion**: Not applicable: the screen draws no animation of its own; the busy indicator
  belongs to the shared rail component.
- **Increase Contrast**: Not determinable from source: all colors are theme tokens.
- **Differentiate Without Color**: Satisfied for model state: unavailable and no-longer-offered are
  shown by the checkbox and the text "No longer offered", not by color. Connect failure and success are
  shown by text; success is also green.

## Feature Flags

The screen is not gated by a flag in this package. Whether a workspace sees it is decided by the
`ai-settings` feature in the backend's feature catalog, which the host's navigation reads; the
services routes do not yet refuse a workspace that lacks it.

## Analytics

Not applicable: the component contains no analytics or telemetry calls. Unexpected failures go to the
shared auth error reporter with a feature and step, which is error reporting, not analytics.

## Privacy

- **Data collected**: A service's name, provider kind, base URL and API key, and the per-model
  switches.
- **Storage**: Server side. The API key is sent on create and on save only when typed and is never
  read back: the row carries only whether a key exists, and the field shows a masked placeholder. The
  client keeps the list in an in-memory cache; the draft key lives in component state only.
- **Transmission**: To the hub API over the data client; the API key input is a password field.
- **Retention**: Not determinable from source: retention is a backend matter.

## Logging

Not applicable: the component contains no logging calls. Failures go to the shared reporter
`reportUnexpectedAuthError` with feature `services` and the step (`list`, `templates`, `save`,
`delete`, `connect`, `refreshModels`). A failed create is reported by the shared create dialog with
feature `create-resource-dialog` and step `save`.

## Platform Notes

- **SwiftUI**: Start from a `NavigationSplitView` whose sidebar is a `List` of services (name as the
  title, provider kind as the subtitle, a `Label` with an SF Symbol) and whose detail is a `Form` with
  `Section`s for Service, Connection and Models. Create in a `.sheet`. The models table is a `Table`
  with `TableColumn`s and a `Toggle` column for Available; format counts with a custom `K`/`M` rule, not
  `formatted()`, to match this recipe. Unsaved-change protection has no automatic equivalent: use a
  confirmation dialog on selection change.
- **Compose**: A list-detail layout (`ListDetailPaneScaffold`) with a `LazyColumn` rail and a form
  `Column`; create in a `ModalBottomSheet` or dialog. The models table is a `LazyColumn` of rows with a
  `Checkbox` (use `Modifier.toggleable` on the row so the whole row is the target and the label is the
  model name) and an `AssistChip` row for capabilities. Keep the draft in a `ViewModel` and compare
  against the loaded baseline for the Save gate.
- **React/Web**: The source platform. The files are `ServicesSection.tsx` (the section, the create form,
  the editor and the models table), `useUserServices.ts` (the cached list and the exported key),
  `AiSettingsSection.tsx` (`ServicesSection` titled "AI Settings"), `index.ts` (the barrel with
  `ServicesSection`, `AiSettingsSection`, `useUserServices` and the key),
  `package.json` and `sources.css`. It is a client component built from the shared UI blocks
  (hierarchical detail view, field groups, button bar, create dialog, rail host) and the shared list
  resource hook. Selection is dual mode (URL or state) and the pane is published into a rail host when
  one exists. The availability call and the revalidation go through the personas data client and the
  list cache.
- **AppKit / UIKit**: A split view controller with an `NSOutlineView` or `UITableView` rail and a form
  detail. The models table is an `NSTableView` with a checkbox cell (`NSButton` of switch type) or a
  `UITableView` with `UISwitch` accessory views. The Save gate maps to `isDocumentEdited` on AppKit, and
  an unsaved-changes sheet on selection change. The Apple model item (`PersonasModels.swift`, generated
  from the OpenAPI) carries `available` as an optional field; read a missing value as available.
- **WinUI 3**: Use a `NavigationView` (or a two-column `Grid` with a `ListView`) for the rail, with an
  `ItemTemplate` showing name and a subtitle `TextBlock`; the pane is a `ScrollViewer` holding
  `StackPanel` groups (`Expander` or `HeaderedContentControl` for Service, Connection and Models). Create
  in a `ContentDialog` whose `IsPrimaryButtonEnabled` follows the draft's validation and whose
  `Opened` event focuses the Name `TextBox`. Provider is a `ComboBox` with `IsEnabled` false when
  editing; API key is a `PasswordBox`. Template choice is a `ComboBox`; informational templates are
  `Border` cards with `HyperlinkButton`s for "Use <name>". The models table is a `DataGrid` (Windows
  Community Toolkit) or an `ItemsRepeater` of rows with a `CheckBox` column bound two-way to
  `Available`; give each box `AutomationProperties.Name` set to the model's display name, and use
  `AutomationProperties.LiveSetting` on the blocker and connect messages. "No longer offered" is a
  `VisualState` of the row (checkbox unchecked, secondary-brush text). Save is a `Button` whose
  `IsEnabled` is `IsDirty && IsValid`; guard navigation with the `NavigationView.ItemInvoked` handler and
  a `ContentDialog`. Numbers use the same K/M rule, not `ToString("N0")`.

## Design Decisions

**Decision**: `PERSONA_SERVICES_CACHE_KEY` keeps its name and its value `"persona-services"` after the
move to this package.
**Rationale**: The design's SDK section states the admin config-set services hook shares the cache
entry through that key; renaming the value would split the cache, and renaming the constant would
break every importer while the personas re-export is in place.
**Approved**: pending

**Decision**: The models a screen shows come from the service row, not from a live model route.
**Rationale**: Per the design, the models table and the persona editor both read the service row's
cached models, so availability is annotated once where the row is built and every screen agrees.
**Approved**: pending

**Decision**: A model switched off that the provider no longer lists is kept in the list as "No longer
offered", unticked.
**Rationale**: Per the design, off records are free text keyed by model name and survive a refresh; the
row stays visible so the record can be cleared.
**Approved**: pending

**Decision**: `ServicesSection` and `useUserServices` are moved with history into this package, and the
personas package re-exports them until Cleanup.
**Rationale**: Per the design, no host import breaks during the phase, and the re-exports are removed
once hosts import from the new package.
**Approved**: pending

**Decision**: The `title` default stays "Persona Services" on `ServicesSection`; `AiSettingsSection`
supplies "AI Settings".
**Rationale**: Existing embedded callers are unchanged, as the source comment on the prop states
("Defaults to the feature's own name so standalone/embedded callers are unchanged").
**Approved**: pending

**Decision**: Creating a service is a modal, never a blank editor leaf.
**Rationale**: The source comment cites the hierarchical detail view's `must-create-in-modal` rule; the
created service is then selected so its Connection and Models groups open.
**Approved**: pending

**Decision**: A failed template read is reported and answered with an empty catalog.
**Rationale**: Per the source comment, the picker is an accelerator, and losing it must not stop anyone
typing a service in by hand.
**Approved**: pending

**Decision**: Edit mode does not re-prompt for URL or header variables.
**Rationale**: The source comment on the draft seed explains the variables cannot be recovered from a
concrete URL, and that object-valued draft fields would read as permanently dirty under the dirty-draft
hook's identity comparison; encode them as primitives if prompting is ever re-enabled.
**Approved**: pending

**Decision**: Save is gated on dirty and valid, and the editor publishes an exit guard only while dirty.
**Rationale**: Per source comments, a grey Save with no reason, and a draft discarded silently on every
exit that skips Save, were defects; registering only on dirt stops browsing from prompting.
**Approved**: pending

**Decision**: The list read reports and rethrows, with the resource's own reporting off.
**Rationale**: Per the source comment, the list is the surface and shows the failure, and one failure
must not be reported twice under two contexts.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |

`separation-of-concerns` is `partial`: transport lives in the personas data module and the services
list in `useUserServices`, but the section, the create form, the editor, the models table and the pure
helpers (substitution, label, number format) share one component file. `unit-test-coverage` is
`partial`: `ServicesSection.test.tsx` covers the Save gate and the exit guard, and the plan's
`ModelsTable.test.tsx` covers the Available checkbox and "No longer offered", but the create modal, the
template logic, the number and price formatting, and Connect and Refresh have no test beside them. `error-response-handling` is `partial`: list, save, delete and create-form failures show a
message, a template failure degrades, but a failed Connect or Refresh is only reported (see the open
question on `refresh-models-failure`). `secure-storage` passes for the client: the API key is sent only
when typed, is shown in a password field and is never read back. `semantic-markup` passes: the models
table is a native table with header cells and the controls are native elements. `caching-strategy`
passes: the services list and the template catalog are each one cached resource, so panes share an entry
and a return to the pane paints from cache while re-reading.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-23 | Mike Fullerton | Initial creation: the AI Settings package for phase 8 |
