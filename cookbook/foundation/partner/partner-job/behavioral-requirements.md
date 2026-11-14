
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

