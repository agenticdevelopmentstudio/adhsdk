---
id: 79810488-c613-4f9b-af2a-4ba9d8ee1c26
title: "Partner Job"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The data shape of a partner job and its steps: a named standing piece of work with an optional timer, guidelines text and ordered steps to type into a terminal or Claude."
platforms:
  - swift
  - macos
tags:
  - partner
  - job
  - model
  - codable
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Job

## Overview

`PartnerJob` and `PartnerJobStep` are the model types for the partner's standing work. A job is "a standing piece of work the partner does, on a timer or on request": it has an identity, a display name, an enabled flag, an optional timer interval in seconds, a block of guidelines text the partner follows, an ordered list of steps, and a flag saying whether the app shipped it. A step is "one step of a job: what to type, where, and when it is the right moment": a name, an environment (the terminal shell or the Claude Code prompt), the command text to type, and a condition describing when typing it is right. Both types are plain `Codable`, `Sendable` and `Equatable` data with no behavior; storage, scheduling and prompt assembly live elsewhere and read these fields.

## Behavioral Requirements

Step shape (`PartnerJobStep`)

- **step-fields**: A step MUST carry exactly four fields: `name` (string), `environment`, `command` (string) and `condition` (string), all required at construction.
- **step-environment-set**: `Environment` MUST be a closed enumeration of two cases, `terminal` and `claude`, whose string raw values are `terminal` and `claude`.
- **step-environment-meaning**: `terminal` MUST mean the command is a shell command line typed into a terminal shell, and `claude` MUST mean it is a prompt typed at Claude Code's prompt; this is the meaning other code (step templating and the prompt's step list) attaches to the two cases.
- **step-command-template**: A step's `command` MAY contain placeholders written as a brace-wrapped word; the type neither parses nor validates them.
- **step-condition-free-text**: A step's `condition` MUST be free text, and an empty string MUST be a valid value meaning no condition.

Job shape (`PartnerJob`)

- **job-fields**: A job MUST carry exactly these fields: `id`, `name`, `isEnabled`, `scheduleSeconds`, `guidelines`, `steps` and `isBuiltIn`.
- **job-identity**: A job MUST be `Identifiable` by its `id` string, and the id is the key every other layer uses to find, store and replace the job.
- **job-initializer-defaults**: The public initializer MUST default `scheduleSeconds` to nil and `isBuiltIn` to false; every other parameter MUST be required.
- **job-schedule-optional**: `scheduleSeconds` MUST be an optional integer; nil means the job has no timer and runs only on request.
- **job-schedule-consumers**: A consumer that arms a timer MUST treat a nil or non-positive `scheduleSeconds` as no timer; the type itself accepts any integer, including zero and negatives. `PartnerController` is the consumer in the source and arms a timer only when the job is enabled and the value is greater than zero.
- **job-steps-ordered**: `steps` MUST preserve the order given; the order is the order the steps are meant to be run.
- **job-steps-may-be-empty**: `steps` MAY be empty.
- **job-built-in-flag**: `isBuiltIn` MUST record that the app, not the owner, created the job; the type attaches no other behavior to it.
- **job-guidelines-free-text**: `guidelines` MUST be free text; an empty string MUST be valid.

Value semantics and coding

- **value-types**: Both types MUST be value types that are `Sendable` and `Equatable`, where equality compares every field, so two jobs with the same id but different guidelines are not equal.
- **codable-keys**: Both types MUST encode to and decode from JSON objects whose keys are the field names exactly as written above (`id`, `name`, `isEnabled`, `scheduleSeconds`, `guidelines`, `steps`, `isBuiltIn`; `name`, `environment`, `command`, `condition`), with the environment as its raw string.
- **decode-requires-fields**: Decoding MUST fail when a non-optional key is missing, including `isBuiltIn`, or when `environment` holds a value other than `terminal` or `claude`.
- **decode-optional-schedule**: Decoding MUST accept a missing or null `scheduleSeconds` as nil.
- **no-validation**: The types MUST NOT validate their contents: an empty id or name, a negative schedule and a duplicate step name are all accepted as given. A caller that puts the id in a file path is responsible for checking it first (`PartnerGuidelinesInstaller` rejects unsafe ids with `InstallError.invalidJobID`).

Concurrency and side effects

- **no-side-effects**: Construction, comparison and coding MUST have no side effect and MUST be safe from any thread, since the types are immutable-by-copy values.

## Appearance

Not applicable — these are data model types, not visual components.

## States

Not applicable — these are plain data types with no runtime state machine and no visual states. A job's enabled or disabled status is the `isEnabled` field, not a state the type moves through.

## Accessibility

Not applicable — these are data model types, not visual components.

## Conformance Test Vectors

The source has no test that targets these two types directly; vectors 001 and 002 are asserted indirectly in `PartnerModelsTests` and `PartnerJobsEditorModelTests`, and the rest are derived from the type declarations.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-job-001 | job-fields, step-fields, job-steps-ordered | Build the default code-reviews job and read its steps (`defaultsHaveTheTwoBuiltInJobs` in `PartnerModelsTests`) | The step names are, in order, `open session`, `review`, `fix` |
| partner-job-002 | value-types | Compare a stored default job's steps to the freshly built default (`testResetToDefaultRestoresStepsAndDeletesGuidelinesFile` in `PartnerJobsEditorModelTests`) | The step arrays are equal, and there are 3 steps |
| partner-job-003 | job-initializer-defaults | `PartnerJob(id: "x", name: "X", isEnabled: true, guidelines: "g", steps: [])` | `scheduleSeconds` is nil and `isBuiltIn` is false |
| partner-job-004 | step-environment-set, codable-keys | Encode a step with environment `claude` | JSON object whose `environment` value is the string `claude`, with keys `name`, `environment`, `command`, `condition` |
| partner-job-005 | decode-requires-fields | Decode a step whose `environment` is `shell` | Decoding throws |
| partner-job-006 | decode-optional-schedule | Decode a job JSON that omits `scheduleSeconds` but has every other key | Decodes with `scheduleSeconds` nil |
| partner-job-007 | decode-requires-fields | Decode a job JSON that omits `isBuiltIn` | Decoding throws |
| partner-job-008 | codable-keys, value-types | Encode a job with two steps and decode the result | The decoded value equals the original |
| partner-job-009 | value-types, job-identity | Two jobs with the same id and every field equal except `guidelines` | Not equal; both report the same `id` |
| partner-job-010 | job-steps-ordered | Build a job with steps `b` then `a` and encode then decode | Decoded steps are still `b` then `a` |
| partner-job-011 | job-steps-may-be-empty, step-condition-free-text | Job with no steps; a step whose condition is `""` | Both construct and round-trip through JSON |
| partner-job-012 | no-validation | Job with id `""`, name `""` and `scheduleSeconds: -5` | Constructs without error and compares equal to an identical copy |
| partner-job-013 | job-schedule-consumers | Enabled job with `scheduleSeconds` of nil, 0 and -5 (consumer rule; see `PartnerController`) | No timer is armed for any of the three |
| partner-job-014 | job-schedule-consumers | Enabled job with `scheduleSeconds` of 1800 | A timer is armed with a 1800-second interval |
| partner-job-015 | no-side-effects | Encode the same job from two threads at once | Both succeed with identical output |

## Edge Cases

- **Empty and missing values**: An empty `steps` array, an empty `guidelines`, an empty `condition` and a nil `scheduleSeconds` are all valid (MUST). A missing non-optional key fails to decode (MUST).
- **Unknown environment**: A step whose environment is not `terminal` or `claude` fails to decode (MUST). A stored job holding such a step makes a whole-array decode fail, because the store decodes all steps together.
- **Boundary values**: `scheduleSeconds` accepts any integer; zero and negative values are valid data but mean no timer to the consumer (MUST at the consumer, MAY at the type). There is no upper bound.
- **Duplicate ids and names**: The types do not enforce uniqueness. The store keys jobs by `id` and replaces a row with the same id (see the store's upsert), so uniqueness is the store's concern, not this type's.
- **Unsafe ids**: An id with path characters is valid data here; callers that use it in a file path MUST check it first (MUST, per no-validation).
- **Concurrent access**: Not applicable beyond value semantics — each copy is independent, so there is no shared mutable state.
- **Network, timeouts, retry, offline**: Not applicable — the types perform no I/O.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PartnerJob.id` | string | none (required) | Identity; also the key in the store and the name used in job files and skills |
| `PartnerJob.name` | string | none (required) | Display name, also used in the system prompt heading for the job |
| `PartnerJob.isEnabled` | bool | none (required) | Whether the job's guidelines and timer are active |
| `PartnerJob.scheduleSeconds` | optional int | nil | Timer interval in seconds; nil or non-positive means no timer |
| `PartnerJob.guidelines` | string | none (required) | Instructions the partner follows for this job |
| `PartnerJob.steps` | array of `PartnerJobStep` | none (required) | Ordered steps to type |
| `PartnerJob.isBuiltIn` | bool | false | Marks a job the app seeds |
| `PartnerJobStep.name` | string | none (required) | Step label |
| `PartnerJobStep.environment` | `terminal` or `claude` | none (required) | Where the command is typed |
| `PartnerJobStep.command` | string | none (required) | Text to type; may carry brace-wrapped placeholders |
| `PartnerJobStep.condition` | string | none (required) | When it is the right moment; empty for none |

## Deep Linking

Not applicable: these are plain data types with no URL surface; nothing in the source routes by URL.

## Localization

Not applicable: the types hold whatever strings the caller supplies and add none of their own; the only fixed strings are the two environment raw values, which are wire identifiers, not user-facing text.

## Accessibility Options

Not applicable: the types render nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach them.

## Feature Flags

Not applicable: the source reads no flag. The `isEnabled` field is job data the owner toggles, not a feature flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: Job names, guidelines text and step commands, all written by the app or the owner; commands may name repositories, models or branches.
- **Storage**: The types store nothing. The `PartnerStore` in the macOS layer persists a job as one row, with the steps encoded as JSON text.
- **Transmission**: The types transmit nothing. Guidelines and step commands are given to the partner process through the system prompt and job files by other types.
- **Retention**: Until the owner deletes the job or resets it to its default.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerJob.swift`, in the `AgenticDeveloperHubSDKCore` framework, importing only `Foundation`. `Identifiable` lets a SwiftUI `List` or `ForEach` use jobs directly. The types are structs with compiler-synthesized `Codable`, `Equatable` and `Sendable`, so key names and the missing-key failure come from the synthesis, not from hand-written code.
- **Compose**: Port as Kotlin `data class` types, with `PartnerJobStep.Environment` as an `enum class`; use `kotlinx.serialization` with `@Serializable` and set `scheduleSeconds` to `Int? = null` with `encodeDefaults` as needed. Keep `isBuiltIn` without a default in the serialized form if missing-key failure on decode is to be preserved; `Boolean = false` would instead accept a missing key.
- **React/Web**: Port as TypeScript interfaces with `environment` typed as the union `terminal` or `claude` and `scheduleSeconds` as `number | null`. Parse stored JSON through a schema validator such as one written with zod so that a missing key or unknown environment fails like the source; plain `JSON.parse` would not. Use the job `id` as the React `key`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the types are UI-framework agnostic. The macOS editor model (`PartnerJobsEditorModel`) edits copies of these structs and saves them back through the store.
- **WinUI 3**: Port as C# `record` types (`public sealed record PartnerJob`) with `init` properties for value equality and immutability, and `PartnerJobStep.Environment` as an `enum` with `[JsonConverter(typeof(JsonStringEnumConverter))]` using camel-case names so the wire values stay `terminal` and `claude`. Use `System.Text.Json` with `JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase` to get the key names, and mark non-optional properties `required` so a missing key fails on decode as in the source; `int?` for `ScheduleSeconds`. Records compare lists by reference, so give the steps a value-comparable collection (such as `ImmutableArray` with a custom equality) if equality must match the source. For binding in XAML, wrap a job in a view model implementing `INotifyPropertyChanged`, since a record is immutable. Persist the steps as a JSON text column in SQLite or a file under `Windows.Storage.ApplicationData`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerJob.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A job carries its guidelines and steps as plain text and data, with no logic.
**Rationale**: The partner follows guidelines written in prose and types steps verbatim, so the model only needs to carry them; templating, scheduling and prompt assembly sit in separate types that read these fields.
**Approved**: pending

**Decision**: `scheduleSeconds` is an optional integer, and non-positive values are left to consumers to treat as no timer.
**Rationale**: The type stays a passive value; the controller that arms timers decides what a usable interval is, so the model needs no validation and can round-trip whatever the editor stored.
**Approved**: pending

**Decision**: The types do not validate ids, names or step contents.
**Rationale**: Validation depends on where the value is used. The installer checks the id before building a file path, and the store keys on the id, so each caller guards what it needs.
**Approved**: pending

**Decision**: Decoding requires every non-optional key, including `isBuiltIn`.
**Rationale**: The source relies on synthesized `Codable`, which has no defaults for missing keys. A stored job written by an older app version without a new field would fail to decode, so adding a field requires a migration or an optional type.
**Approved**: pending

**Decision**: A step's environment is a closed two-case set rather than free text.
**Rationale**: Step templating treats a terminal command as a shell line and quotes values into it, while a Claude step is a prompt typed as written; the two cases drive that difference, so an unknown value must fail rather than be guessed.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

The types are inert data with no persistence, scheduling or UI code, so separation of concerns passes. No test targets the types' coding contract directly: the existing tests read them through the defaults and the editor model, and nothing asserts the key names, the unknown-environment failure or the missing-key failure, so coverage is partial. Data integrity is partial because the types accept any contents and rely on each caller to guard ids and intervals.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
