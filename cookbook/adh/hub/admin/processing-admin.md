---
id: d3ba2e4e-bfce-4876-a05b-4ad7db88b34d
title: "Processing Admin"
type: ingredient
version: 1.0.0
status: draft
language: en
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The operator's AI processing panes: worker tokens with the Pool checkbox, and the dead jobs list with Retry in AiNodesPane."
platforms:
  - typescript
  - web
tags:
  - hub
  - admin
  - processing
  - jobs
depends-on: []
related:
  - 0bcb370d-a44f-48a8-a313-0266c2f86e51
references: []
approved-by: ""
approved-date: ""
---

# Processing Admin

## Overview

The operator's AI processing panes in `@adh-sdk/adh-admin`: `AiNodesPane` (the hub's AI nodes, their
logs and settings) and the `WorkerTokens` section it mounts, over the admin-gated
`/api/v1/processing` client in `api/processing.ts`. This ingredient records the parts phase 9 (Jobs)
changes, written before that code:

- The worker token create form gains a **Pool** checkbox. A pool token also carries the
  `ai-processing:pool` scope, which lets a hub node claim AI steps of jobs ([adhsdk.ingredient.adh.hub.jobs](cookbook:0bcb370d-a44f-48a8-a313-0266c2f86e51)) from every
  product.
- `AiNodesPane` gains a **Dead jobs** section that lists the queue's dead rows, newest first, each with
  Retry.

The operator admin topics are unchanged. There is no operator "Jobs" topic today, so nothing is
relabelled.

## Behavioral Requirements

### Worker tokens

- **worker-token-name-required**: The create dialog MUST ask for a name, and MUST NOT submit a name that is
  blank after trimming.
- **worker-token-pool-checkbox**: The create dialog MUST offer a "Pool" checkbox, unchecked by default,
  whose description says that a pool token can claim AI steps of jobs from every product. The create
  MUST send `{ name, pool }`, with `pool` true only when the box is checked.
- **worker-token-scope-shown**: The tokens list MUST show whether each token is a pool token, read from
  the token's scopes (`ai-processing:pool`).
- **worker-token-reveal-once**: The created token MUST be shown once in a read-only field with a copy
  button, and closing the reveal MUST ask "Close without copying?" first.
- **worker-token-revoke-confirm**: Revoke MUST ask for confirmation and MUST say that every node using the
  token stops working.

### Dead jobs

- **dead-jobs-section**: `AiNodesPane` MUST show a "Dead jobs" section listing the queue's dead rows through
  `listDeadJobs`, which reads `GET /api/v1/processing/jobs?status=dead`, newest first. Each row shows
  its type, its ecosystem, its attempts, its last error and when it died.
- **dead-jobs-retry**: Each dead row MUST offer Retry, which calls `retryDeadJob(id)` (`POST
  /api/v1/processing/jobs/:id/retry`) and removes the row from the list once the call succeeds.
- **dead-jobs-retry-failure-shown**: A failed retry MUST be shown beside the list, and the row MUST stay.
- **dead-jobs-empty**: With no dead rows the section MUST say "No dead jobs."

### Topics

- **admin-topics-unchanged**: The operator admin topics MUST stay as they are. No "Jobs" or "Queue" topic
  is added, and none is renamed.

## Appearance

- **Layout**: The Dead jobs section sits in `AiNodesPane` below the worker tokens, as an editable list
  with the same columns, sorting and search as the other processing lists.
- **Checkbox**: The Pool checkbox sits under the Name field in the create dialog, with its description in
  the muted text token.
- **Error text**: The last error is shown cut to one line, with the whole error in its title.

## States
| State | Appearance change |
|-------|------------------|
| Loading | The dead jobs list shows the shared list's loading state. |
| Read failed | The list shows "Couldn't load dead jobs" with the error. |
| Empty | The list says "No dead jobs." |
| Retrying | The row's Retry is disabled until the call returns. |
| Retry failed | The error shows beside the list and the row stays. |
| Pool checked | The create sends `pool: true`; the created token is listed as a pool token. |

## Accessibility

- **Role/trait**: The Dead jobs section is a `section` labelled "Dead jobs". The Pool control is a native
  checkbox.
- **pool-checkbox-label**: The Pool checkbox MUST have the accessible name "Pool".
- **retry-label**: Each row's Retry button MUST name the row, for example `aria-label="Retry <type>
  <id>"`, so one row's button can be told from the next.
- **Keyboard**: Every control is a native input, checkbox or button.

## Conformance Test Vectors

The Pool checkbox, the Dead jobs section and the two client calls are not written yet. These vectors
are the tests the package's `__tests__/` MUST carry for them.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| processing-admin-001 | worker-token-pool-checkbox | Open the create dialog | The Pool checkbox is present and unchecked. |
| processing-admin-002 | worker-token-pool-checkbox | Create a token named `edge-1` with Pool checked | The create call's body is `{ name: "edge-1", pool: true }`. |
| processing-admin-003 | worker-token-pool-checkbox, worker-token-name-required | Create a token named `  edge-2 ` with Pool unchecked | The create call's body is `{ name: "edge-2", pool: false }`. |
| processing-admin-004 | dead-jobs-section | Two dead rows, the newer second in the response | Both are listed with the newer first. |
| processing-admin-005 | dead-jobs-retry | Retry a dead row; the call succeeds | `retryDeadJob` is called with the row's id and the row leaves the list. |
| processing-admin-006 | dead-jobs-retry-failure-shown | Retry a dead row; the call answers 409 | The error is shown and the row stays. |
| processing-admin-007 | dead-jobs-empty | No dead rows | The section says "No dead jobs." |
| processing-admin-008 | admin-topics-unchanged | The operator admin topics | No topic is labelled "Jobs" or "Queue". |

## Edge Cases

- **Null and empty input**: No dead rows shows "No dead jobs." (MUST). A dead row with no last error shows
  an em dash (MUST).
- **Concurrent access**: A row retried by another operator first answers with an error, which is shown,
  and the row leaves the list on the next read (MUST).
- **Old tokens**: Tokens minted before phase 9 carry only `ai-processing:worker` and are listed as not
  pool tokens (MUST).

## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `help` (AiNodesPane) | `ReactNode` | omitted | Help shown beside the pane title, as today. |
| `pool` (create input) | boolean | `false` | Whether the minted worker token also carries `ai-processing:pool`. |

## Deep Linking

Not applicable: the panes are mounted by the operator admin site, which owns the URL; the Dead jobs
section is part of the AI Nodes page and has no route of its own.

## Localization
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | Pool | Create dialog checkbox |
| n/a (literal) | Dead jobs | Section heading |
| n/a (literal) | No dead jobs. | Empty list |
| n/a (literal) | Couldn't load dead jobs | Read failure |
| n/a (literal) | Retry | Row action |

## Accessibility Options

- **Reduce Motion**: Not applicable: nothing animates.
- **Increase Contrast**: All colors are theme tokens.
- **Differentiate Without Color**: Pool tokens and dead rows are shown by text, not color.

## Feature Flags

Not gated by a flag in this package. The operator routes are admin-gated by the backend. Dead rows of
jobs steps exist only once the `jobs_feature` switch lets runs start.

## Analytics

Not applicable: the panes make no analytics or telemetry calls.

## Privacy

- **Data collected**: None new. A dead row shows its type, ecosystem, attempts and last error. It does not
  show the row's payload, which can hold a customer's prompt.
- **Storage**: The worker token is stored by the backend only as a hash and is shown once.
- **Pool tokens**: A pool token's node sees prompts from every product, so the checkbox's description
  says so and operators should mint pool tokens only for hub nodes.

## Logging

Not applicable: the panes contain no logging calls. Failures are shown in the shared error text.

## Platform Notes

- **SwiftUI**: A `Toggle("Pool", isOn:)` in the create `Form`, and a `List` of dead rows with a trailing
  "Retry" `Button` per row; disable it while its task runs.
- **Compose**: A `Checkbox` with a `Text` label in a `Row` with `Modifier.toggleable`, and a `LazyColumn` of dead
  rows each with a `TextButton("Retry")`.
- **React/Web**: The source platform. The checkbox is a native input in the shared create dialog, the
  list is the shared editable list, and the two calls are `authedJson` functions in `api/processing.ts`
  with react-query hooks beside the others.
- **AppKit / UIKit**: An `NSButton` checkbox (or `UISwitch`) in the sheet, and an `NSTableView` or
  `UITableView` of dead rows with a Retry button cell.
- **WinUI 3**: A `CheckBox` in the `ContentDialog`, and a `ListView` of dead rows with a Retry
  `Button` in each item template.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/features/adh-admin/src/processing/WorkerTokens.tsx` | planned |
| web | `packages/web/packages/features/adh-admin/src/panes/AiNodesPane.tsx` | planned |
| web | `packages/web/packages/features/adh-admin/src/api/processing.ts` | planned |

## Design Decisions

**Decision**: Dead jobs go in a section of `AiNodesPane`, not a new topic.
**Rationale**: Per the phase 9 design, there was no dead job list to add Retry to and no "Jobs" topic to
relabel, and the topics stay unchanged.
**Approved**: pending

**Decision**: The Pool scope is a checkbox on the existing worker token mint.
**Rationale**: Per the design (call C9), a pool token is a worker token with one more scope, so it reuses
the mint, the reveal and the revoke.
**Approved**: pending

**Decision**: A dead row shows no payload.
**Rationale**: A step's payload can hold a customer's prompt, and the operator needs only the type,
error and attempts to decide to retry.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | pending | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | pending | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | pending | Access Patterns |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | pending | Security |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | pending | Accessibility |

Every check is `pending` until the phase 9 code is written.

## Change History
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-23 | Mike Fullerton | Initial creation: the Pool checkbox and the Dead jobs section for phase 9, written before the code |
