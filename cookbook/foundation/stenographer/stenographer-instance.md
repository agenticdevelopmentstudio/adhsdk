---
id: fe798f91-076e-41fc-9713-907b744c5539
title: "Stenographer Instance"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Which Stenographer a process belongs to: the installed default, or a named development copy resolved and validated from its definition file."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - identifiers
  - paths
depends-on:
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
related:
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
references: []
approved-by: ""
approved-date: ""
---

# Stenographer Instance

## Overview

`StenographerInstance` says which Stenographer the current process belongs to. The **default** instance is the one a person installs: it is unnamed and resolves every value exactly as Stenographer always has (label `com.agenticdevelopmentstudio.stenographer`, HTTP port `22847`). A **named** instance (for example `dev-trimming`) is a development copy that runs beside the installed one, with its own data root, label and HTTP port, and the rules here keep it from touching anything the installed copy owns.

A named instance exists only if its definition file does: `~/Library/Application Support/com.agenticdevelopmentstudio.stenographer.instances/<name>.json`, which `scripts/stenographer_instance.py` writes. Asking for a name with no definition is a hard error, because creating an empty store for a typo would look like data loss.

The type is a `Sendable`, `Equatable` struct holding an optional `Definition`. It provides the selection rule (`requestedName(environment:arguments:)`), the resolver (`resolve(name:home:)`), the validator (`validate(_:fileName:home:)`) and the process-wide value `current`, which [adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43) reads to derive its label, port and paths. The passive gates that stop a named instance from acting on installed state live outside this type, in the daemon's `InstancePolicy` and the app's `StenographerInstances`.

## Behavioral Requirements

### Data shapes

- **definition-fields**: `Definition` MUST carry exactly three fields, `name` (string), `dataRoot` (string) and `httpPort` (integer), and MUST decode from and encode to a JSON object with the keys `name`, `dataRoot` and `httpPort`.
- **definition-unknown-keys**: Decoding a definition MUST ignore JSON keys other than the three fields.
- **default-has-no-definition**: `StenographerInstance.default` MUST hold no definition, and `isDefault` MUST be true exactly when the definition is absent.
- **default-values**: The default instance MUST report `name` as absent, `label` as `com.agenticdevelopmentstudio.stenographer`, `httpPort` as `22847` and `dataRoot` as absent.
- **named-label**: A named instance's `label` MUST be the base label, a dot and the instance name (`com.agenticdevelopmentstudio.stenographer.<name>`).
- **named-port**: A named instance's `httpPort` MUST be the definition's `httpPort`.
- **named-data-root**: A named instance's `dataRoot` MUST be a directory URL for the definition's `dataRoot` string.
- **construction-closed**: Callers outside the module MUST NOT be able to build a named instance except through `resolve(name:home:)`; the memberwise initializer is internal, and only `default` and `resolve` produce values.
- **equality**: Two instances MUST compare equal exactly when their definitions are equal (both absent, or equal in all three fields).

### Constants

- **base-label**: `baseLabel` MUST be `com.agenticdevelopmentstudio.stenographer`.
- **default-port**: `defaultHTTPPort` MUST be `22847`.
- **reserved-ports**: `reservedHTTPPorts` MUST be the set {22847, 22848, 22849}: the installed daemon's HTTP port, the installed account router's port (`StenographerIdentifiers.routerPort`) and the retired Kitchen daemon adkd's port.
- **reserved-names**: `reservedNames` MUST be the set {`usagewidget`, `instances`, `daemon`}: the usage widget's bundle id suffix, the definitions directory's suffix and the installed daemon's launch-throttle identifier suffix.
- **selection-keys**: The environment key MUST be `STENOGRAPHER_INSTANCE` and the argument flag MUST be `-instance`.
- **socket-constants**: `socketFileName` MUST be `stenographer.sock` and `socketPathLimit` MUST be `104` (the size of Darwin's `sun_path`, including the terminating NUL).
- **definitions-directory**: `definitionsDirectory(home:)` MUST return `<home>/Library/Application Support/com.agenticdevelopmentstudio.stenographer.instances/` as a directory URL.

### Selecting a name

- **environment-wins**: `requestedName(environment:arguments:)` MUST return the `STENOGRAPHER_INSTANCE` value when that key is present, without consulting the arguments.
- **empty-environment-is-default**: When `STENOGRAPHER_INSTANCE` is present with an empty value, `requestedName` MUST return absent (the default), even when the arguments name an instance.
- **argument-flag**: When the environment key is absent, `requestedName` MUST return the argument that immediately follows the first `-instance` in the arguments.
- **argument-missing-value**: When `-instance` is the last argument, or the arguments contain no `-instance`, `requestedName` MUST return absent.
- **empty-argument-is-default**: When the argument after `-instance` is an empty string, `requestedName` MUST return absent.
- **selection-unvalidated**: `requestedName` MUST NOT validate the name it returns; validation happens in `resolve`.

### Resolving an instance

- **resolve-absent**: `resolve(name:home:)` MUST return the default instance when `name` is absent, without touching the file system.
- **name-pattern**: `resolve` MUST throw `invalidName(name)` when `name` does not match `[a-z0-9][a-z0-9-]{0,31}` in its entirety (1 to 32 characters, lowercase ASCII letters, digits and hyphens, not starting with a hyphen).
- **definition-required**: `resolve` MUST throw `undefined(name:expectedAt:)`, carrying the definition file's path, when no file exists at `<definitionsDirectory>/<name>.json`.
- **definition-unreadable**: `resolve` MUST throw `unreadable(path:reason:)` when the file exists but cannot be read or does not decode as a `Definition`, with `reason` the textual description of the underlying error.
- **resolve-validates**: After decoding, `resolve` MUST run `validate(_:fileName:home:)` with `fileName` set to the requested name, and MUST propagate its error unchanged.
- **resolve-result**: When validation passes, `resolve` MUST return a named instance holding the decoded definition.
- **resolve-order**: `resolve` MUST check in this order and throw the first failure: name pattern, file existence, read and decode, then validation. A reserved name with no definition file therefore throws `undefined`, not `reservedName`.

### Validating a definition

- **validate-order**: `validate` MUST check in this order and throw the first failure: name match, reserved name, absolute data root, port, overlap with installed state, overlap with another instance, port held by another instance, socket path length.
- **name-match**: `validate` MUST throw `nameMismatch(file:declared:)` when the definition's `name` differs from `fileName`.
- **name-reserved**: `validate` MUST throw `reservedName(name)` when the definition's `name` is in `reservedNames`.
- **validate-no-pattern**: `validate` MUST NOT apply the name pattern itself; only `resolve` does.
- **absolute-data-root**: `validate` MUST throw `relativeDataRoot(dataRoot)` when `dataRoot` does not begin with `/`.
- **port-range**: `validate` MUST throw `invalidPort(port)` when `httpPort` is outside 1024 to 65535 inclusive.
- **port-not-reserved**: `validate` MUST throw `invalidPort(port)` when `httpPort` is in `reservedHTTPPorts`.
- **port-unique-across-instances**: `validate` MUST throw `portTakenByAnotherInstance(port:instance:)`, naming the first other definition in file-name order whose `httpPort` equals this definition's, so a named instance's port is its own and two instances never contend for one port. It considers the same peers as `instance-overlap` (`other-definitions`), so a definition's own file never collides with it and an unreadable peer is skipped.
- **protected-roots**: `protectedRoots(home:)` MUST return, in order, `<home>/Library/Application Support/<baseLabel>`, `<home>/Library/Logs/<baseLabel>`, `<home>/Library/Application Support/<legacyLabel>`, `<home>/Library/Logs/<legacyLabel>` and `<home>/.claude`, where `legacyLabel` is `com.agentic-cookbook.stenographer`.
- **installed-overlap**: `validate` MUST throw `overlapsInstalledState(dataRoot:protected:)`, naming the first protected root in `protectedRoots` order, when the canonical data root equals, contains or lies inside that protected root.
- **instance-overlap**: `validate` MUST throw `overlapsAnotherInstance(dataRoot:instance:otherRoot:)`, naming the first other definition in file-name order, when the canonical data root equals, contains or lies inside that definition's canonical data root.
- **overlap-by-components**: Overlap MUST be decided by whole path components, so `com.agenticdevelopmentstudio.stenographer.instances` does not overlap `com.agenticdevelopmentstudio.stenographer`.
- **other-definitions**: `otherDefinitions(excluding:home:)` MUST consider every `.json` file in the definitions directory except `<name>.json`, sorted by file name, and MUST skip any file that cannot be read, does not decode, declares a name different from its file name, or has a data root that does not begin with `/`.
- **other-definitions-missing-directory**: When the definitions directory is missing or unreadable, `otherDefinitions` MUST return an empty list.
- **socket-length**: `validate` MUST throw `socketPathTooLong(path:limit:)` when the path `<dataRoot>/stenographer.sock`, built from `dataRoot` as written, is 104 or more UTF-8 bytes.

### Canonical paths

- **canonical-dot**: Canonicalisation MUST drop `.` components.
- **canonical-dotdot**: Canonicalisation MUST apply `..` against the components resolved so far, and MUST leave the path at the root when there is nothing to remove.
- **canonical-symlinks**: Canonicalisation MUST replace each prefix that exists on disk with its real path, following every symlink in it.
- **canonical-dangling**: Canonicalisation MUST follow a dangling symlink to its target (absolute as written, relative against the components resolved so far) and continue with the remaining components, to a depth of at most 32 links, after which the component is kept as written.
- **canonical-missing**: Canonicalisation MUST keep components that do not exist as written.
- **canonical-case**: Canonicalisation MUST lowercase every component after resolving, so comparisons are case-insensitive.
- **canonical-data-volume**: Canonicalisation MUST drop a leading `/System/Volumes/Data` (matched case-insensitively) both before and after resolving.
- **canonical-python-parity**: Canonicalisation MUST produce the same components as Python's `os.path.realpath` followed by the lowercasing and firmlink rules above, because `scripts/stenographer_instance.py` (`check_definition`) uses that to enforce the same rules.

### The process instance

- **current-once**: `current` MUST be resolved once per process, from the process's environment and arguments through `requestedName`, against the current user's home directory.
- **current-failure-exit**: When resolution of `current` throws, the process MUST write `stenographer: <error description>` and a newline to standard error.
- **current-failure-status**: When resolution of `current` throws, the process MUST exit with status 78 (`EX_CONFIG`), a normal exit rather than a crash.

### Errors

- **error-equatable**: `ResolutionError` MUST be `Equatable`, comparing case and associated values.
- **error-description**: Each `ResolutionError` case MUST produce the English description listed under Localization, with its associated values substituted.

### Concurrency and side effects

- **sendable**: `StenographerInstance` and `Definition` MUST be `Sendable`, so a resolved instance may be shared across tasks and threads.
- **read-only**: `resolve`, `validate`, `otherDefinitions` and `protectedRoots` MUST NOT create, modify or delete any file; they only test existence, list the definitions directory, read definition files and resolve real paths.

## Appearance

Not applicable — this is an instance-selection and validation model, not a visual component.

## States

Not applicable — this is an instance-selection and validation model, not a visual component.

## Accessibility

Not applicable — this is an instance-selection and validation model, not a visual component.

## Conformance Test Vectors

Vectors 041 to 044 are `StenographerInstancePortTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/StenographerInstancePortTests.swift`); no other test in this repository exercises the type. Its doc comment on `validate` names `tests/fixtures/instance_definition_cases.json` as the cases both it and `scripts/stenographer_instance.py` are tested against, but that fixture is not among the given sources, so every other vector below is derived from the source. In the vectors, `H` is a scratch home directory (for example `/private/tmp/h`) and `D` is `H/Library/Application Support/com.agenticdevelopmentstudio.stenographer.instances`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-instance-001 | default-has-no-definition, default-values | `StenographerInstance.default` | `isDefault` true; `name` absent; `label` `com.agenticdevelopmentstudio.stenographer`; `httpPort` 22847; `dataRoot` absent. |
| stenographer-instance-002 | base-label, default-port, reserved-ports, reserved-names, selection-keys, socket-constants | The static constants. | `baseLabel` `com.agenticdevelopmentstudio.stenographer`; `defaultHTTPPort` 22847; `reservedHTTPPorts` {22847, 22848, 22849}; `reservedNames` {usagewidget, instances, daemon}; `environmentKey` `STENOGRAPHER_INSTANCE`; `argumentFlag` `-instance`; `socketFileName` `stenographer.sock`; `socketPathLimit` 104. |
| stenographer-instance-003 | definitions-directory | `definitionsDirectory(home: /h)` | `/h/Library/Application Support/com.agenticdevelopmentstudio.stenographer.instances/`. |
| stenographer-instance-004 | environment-wins | environment `{STENOGRAPHER_INSTANCE: "dev"}`, arguments `["app", "-instance", "other"]` | `"dev"`. |
| stenographer-instance-005 | empty-environment-is-default | environment `{STENOGRAPHER_INSTANCE: ""}`, arguments `["app", "-instance", "other"]` | absent. |
| stenographer-instance-006 | argument-flag | environment `{}`, arguments `["app", "-instance", "dev", "-instance", "x"]` | `"dev"` (the first flag wins). |
| stenographer-instance-007 | argument-missing-value | environment `{}`, arguments `["app", "-instance"]`; and arguments `["app"]` | absent in both. |
| stenographer-instance-008 | empty-argument-is-default | environment `{}`, arguments `["app", "-instance", ""]` | absent. |
| stenographer-instance-009 | selection-unvalidated | environment `{STENOGRAPHER_INSTANCE: "Bad Name"}` | `"Bad Name"`, returned unchanged. |
| stenographer-instance-010 | resolve-absent | `resolve(name: nil, home: H)` with `D` absent | The default instance; no error. |
| stenographer-instance-011 | name-pattern | `resolve(name: "Dev")`, `resolve(name: "-dev")`, `resolve(name: "")`, and a 33-character name | `invalidName` with the given name, for each. |
| stenographer-instance-012 | name-pattern | `resolve(name: "a")` and a 32-character name of `a`, each with a valid definition file | Both resolve; a one-character and a 32-character name match the pattern. |
| stenographer-instance-013 | definition-required, resolve-order | `resolve(name: "dev")` with no `D/dev.json`; and `resolve(name: "daemon")` with no `D/daemon.json` | `undefined(name: "dev", expectedAt: "D/dev.json")`; the reserved name also throws `undefined`, not `reservedName`. |
| stenographer-instance-014 | definition-unreadable | `D/dev.json` contains `{"name": "dev", "dataRoot": "/tmp/x"}` (no `httpPort`) | `unreadable` with the file's path and the decoding error's description. |
| stenographer-instance-015 | definition-unreadable | `D/dev.json` is a directory | `unreadable` with the file's path. |
| stenographer-instance-016 | definition-fields, definition-unknown-keys, resolve-result, named-label, named-port, named-data-root | `D/dev.json` is `{"name": "dev", "dataRoot": "/private/tmp/steno-dev", "httpPort": 23000, "extra": 1}` | A named instance: `isDefault` false; `name` `dev`; `label` `com.agenticdevelopmentstudio.stenographer.dev`; `httpPort` 23000; `dataRoot` a directory URL whose path is `/private/tmp/steno-dev`. |
| stenographer-instance-017 | name-match | `D/dev.json` declares `"name": "other"` | `nameMismatch(file: "dev", declared: "other")`. |
| stenographer-instance-018 | name-reserved | `D/daemon.json` declares `"name": "daemon"` with an otherwise valid body | `reservedName("daemon")`. |
| stenographer-instance-019 | absolute-data-root | `dataRoot` `"steno-dev"` | `relativeDataRoot("steno-dev")`. |
| stenographer-instance-020 | port-range | `httpPort` 1023, then 65536 | `invalidPort(1023)`, then `invalidPort(65536)`. |
| stenographer-instance-021 | port-range | `httpPort` 1024, then 65535 | Both pass the port check. |
| stenographer-instance-022 | port-not-reserved | `httpPort` 22847, 22848 and 22849 | `invalidPort` for each. |
| stenographer-instance-023 | protected-roots | `protectedRoots(home: /h)` | Five URLs in order: `/h/Library/Application Support/com.agenticdevelopmentstudio.stenographer`, `/h/Library/Logs/com.agenticdevelopmentstudio.stenographer`, `/h/Library/Application Support/com.agentic-cookbook.stenographer`, `/h/Library/Logs/com.agentic-cookbook.stenographer`, `/h/.claude`. |
| stenographer-instance-024 | installed-overlap | `dataRoot` `H/Library/Application Support/com.agenticdevelopmentstudio.stenographer/dev` | `overlapsInstalledState` naming the current support directory (the data root lies inside it). |
| stenographer-instance-025 | installed-overlap | `dataRoot` equal to `H` | `overlapsInstalledState` naming the current support directory (the data root contains it). |
| stenographer-instance-026 | installed-overlap, canonical-case | `dataRoot` `H/library/logs/com.agentic-cookbook.stenographer` | `overlapsInstalledState` naming the legacy logs directory. |
| stenographer-instance-027 | installed-overlap, canonical-data-volume | `dataRoot` `/System/Volumes/Data` followed by `H/.claude/steno` | `overlapsInstalledState` naming `H/.claude`. |
| stenographer-instance-028 | canonical-dotdot | `dataRoot` `H/tmp/../.claude/x` | `overlapsInstalledState` naming `H/.claude`. |
| stenographer-instance-029 | overlap-by-components | `dataRoot` `D/dev-data` | No installed-state overlap; the definitions directory is not a protected root. With `H` = `/private/tmp/h` the socket path is then 121 bytes, so validation ends in `socketPathTooLong`. |
| stenographer-instance-030 | instance-overlap, other-definitions | `D/a.json` has `dataRoot` `/private/tmp/steno`; `D/b.json` has `dataRoot` `/private/tmp/steno/b` | Resolving `b` throws `overlapsAnotherInstance(dataRoot: "/private/tmp/steno/b", instance: "a", otherRoot: "/private/tmp/steno")`. |
| stenographer-instance-031 | other-definitions | `D/a.json` is not valid JSON but contains the text `/private/tmp/steno`; `D/b.json` is valid with `dataRoot` `/private/tmp/steno` | Resolving `b` succeeds; the unreadable peer is skipped. |
| stenographer-instance-032 | canonical-symlinks | `/private/tmp/link` is a symlink to `H/.claude`; `dataRoot` `/private/tmp/link/steno` | `overlapsInstalledState` naming `H/.claude`. |
| stenographer-instance-033 | socket-length | `dataRoot` is an 85-byte absolute path (socket path 103 bytes) | Passes the socket check. |
| stenographer-instance-034 | socket-length | `dataRoot` is an 86-byte absolute path (socket path 104 bytes) | `socketPathTooLong(path: <dataRoot>/stenographer.sock, limit: 104)`. |
| stenographer-instance-035 | validate-order | `D/dev.json` declares `"name": "daemon"`, `dataRoot` `"x"`, `httpPort` 1 | `nameMismatch(file: "dev", declared: "daemon")`, the first check. |
| stenographer-instance-036 | error-description | `invalidPort(80)`; `reservedName("daemon")` | `instance httpPort 80 must be 1024-65535 and not one of 22847, 22848, 22849`; `instance name 'daemon' is reserved: com.agenticdevelopmentstudio.stenographer.daemon already names something else`. |
| stenographer-instance-037 | current-failure-exit, current-failure-status | Launch a process that reads `current` with `STENOGRAPHER_INSTANCE=nosuch` and no definition | Standard error is `stenographer: instance 'nosuch' is not defined (no <path>); create it with scripts/stenographer_instance.py create` and the exit status is 78. |
| stenographer-instance-038 | current-once | Read `current` twice in one process after changing the definition file between reads | Both reads return the same value; the file is read once. |
| stenographer-instance-039 | equality | Two named instances resolved from the same definition; one named and the default | Equal; not equal. |
| stenographer-instance-040 | read-only | Resolve a valid definition and an invalid one in `H` | No file or directory under `H` is created, modified or deleted. |
| stenographer-instance-041 | port-unique-across-instances, error-description | `D/alpha.json` declares `httpPort` 22950; validate a `beta` definition with `httpPort` 22950 and a distinct data root (`testAPortAnotherDefinitionHoldsIsRefused`) | `portTakenByAnotherInstance(port: 22950, instance: "alpha")`. |
| stenographer-instance-042 | port-unique-across-instances, other-definitions | `D/alpha.json` and `D/beta.json` both declare `httpPort` 22951; resolve `beta` (`testResolvingADefinitionWhosePortIsTakenFails`) | `portTakenByAnotherInstance(port: 22951, instance: "alpha")`. |
| stenographer-instance-043 | port-unique-across-instances | `D/alpha.json` declares 22952; validate `beta` with 22953 (`testDistinctPortsAreAccepted`) | No error. |
| stenographer-instance-044 | port-unique-across-instances, other-definitions | Only `D/alpha.json`, `httpPort` 22954; resolve `alpha` (`testADefinitionDoesNotCollideWithItsOwnFile`) | Resolves with `httpPort` 22954. |

## Edge Cases

- **Null / empty input**: An absent name MUST resolve to the default instance. An empty `STENOGRAPHER_INSTANCE` value or an empty argument after `-instance` MUST be treated as absent. An empty name passed straight to `resolve` MUST throw `invalidName`.
- **Environment shadows the argument**: A present but empty `STENOGRAPHER_INSTANCE` MUST select the default even when `-instance <name>` is passed, because the environment is consulted first and the arguments are not read when the key exists.
- **Flag without value**: `-instance` as the last argument MUST select the default. A following argument that looks like another flag (`-instance -x`) MUST be returned as the name and then refused by `resolve` with `invalidName`.
- **Boundary values**: Names of 1 and 32 characters MUST pass the pattern and 33 MUST fail. Ports 1024 and 65535 MUST pass and 1023 and 65536 MUST fail. A socket path of 103 bytes MUST pass and 104 MUST fail; with the 18-byte `/stenographer.sock` suffix that is a data root of at most 85 bytes. Lengths are UTF-8 bytes, so a non-ASCII data root reaches the limit with fewer characters.
- **Reserved name with no file**: MUST throw `undefined`, because the file check precedes validation.
- **Data root of `/` or the home directory**: MUST throw `overlapsInstalledState`, because it contains every protected root.
- **Data root inside the definitions directory**: MUST be accepted as far as installed state goes, because the comparison is by whole components and the definitions directory is not a protected root.
- **Case and firmlink aliases**: A data root that differs from a protected root only by letter case, or by a leading `/System/Volumes/Data`, MUST be treated as the same path.
- **Symlinks**: An existing symlink anywhere in the data root MUST be followed before comparing. A dangling symlink MUST be followed to its target. A symlink chain deeper than 32 dangling links MUST stop being followed, and the remaining component MUST be kept as written.
- **Unreadable peer definitions**: A peer file that cannot be read, does not decode, declares a mismatched name or has a relative data root MUST be skipped in the overlap and port checks; that peer is refused only when it is itself resolved.
- **Two instances with the same port**: MUST be refused: resolving the second throws `portTakenByAnotherInstance` naming the first (`port-unique-across-instances`).
- **Concurrent access**: `current` is a Swift `static let`, initialised once and thread-safe. `resolve` holds no shared state and may run on any thread. The file system is not locked: a definition file written or removed between the existence check and the read MUST surface as `undefined` or `unreadable`, and two definitions written at the same moment may each pass the overlap check before the other exists; the script that writes definitions owns that ordering.
- **Error states**: Every failure MUST be thrown as a `ResolutionError`; no failure is swallowed in `resolve` or `validate`. `otherDefinitions` deliberately returns an empty list for a missing directory and drops unreadable peers. `current` MUST turn a thrown error into a stderr line and exit status 78.
- **Offline / disconnected state**: Not applicable: the type performs no network access; `httpPort` is a number the daemon binds elsewhere.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_INSTANCE` | environment variable | unset | Names the instance; wins over the argument; an empty value selects the default. |
| `-instance <name>` | process argument | absent | Names the instance when the environment variable is unset. |
| `home` | `URL` | the current user's home directory (for `current`) | The root of the definitions directory and of the protected roots; passed explicitly to `resolve`, `validate`, `definitionsDirectory` and `protectedRoots`. |
| `<name>.json` | definition file | none | `{"name", "dataRoot", "httpPort"}` in the definitions directory, written by `scripts/stenographer_instance.py create`. |

The type reads no settings key and takes no injected dependency besides `home`; it uses the real file system through `FileManager.default` and `realpath`.

## Deep Linking

Not applicable: the type defines no URL scheme or route.

## Localization

The `ResolutionError` descriptions are hardcoded English strings and are not localized. They reach a person through the stderr line that `current` writes before exiting.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `invalidName` | `instance name '<name>' must match [a-z0-9][a-z0-9-]{0,31}` | Name fails the pattern. |
| `reservedName` | `instance name '<name>' is reserved: com.agenticdevelopmentstudio.stenographer.<name> already names something else` | Name is in `reservedNames`. |
| `undefined` | `instance '<name>' is not defined (no <path>); create it with scripts/stenographer_instance.py create` | No definition file. |
| `unreadable` | `instance definition <path> is unreadable: <reason>` | Read or decode failed. |
| `nameMismatch` | `instance definition <file>.json declares name '<declared>'` | Declared name differs from the file name. |
| `relativeDataRoot` | `instance dataRoot '<root>' must be an absolute path` | Data root does not start with `/`. |
| `invalidPort` | `instance httpPort <port> must be 1024-65535 and not one of 22847, 22848, 22849` | Port out of range or reserved; the reserved list is sorted ascending. |
| `overlapsInstalledState` | `instance dataRoot '<root>' overlaps <protected>, which the installed Stenographer owns` | Data root overlaps a protected root. |
| `overlapsAnotherInstance` | `instance dataRoot '<root>' overlaps instance '<instance>''s dataRoot '<otherRoot>'` | Data root overlaps another definition's. |
| `portTakenByAnotherInstance` | `instance httpPort <port> is already instance '<instance>''s httpPort` | Another definition declares the same port. |
| `socketPathTooLong` | `instance socket path <path> is <bytes> bytes; the limit is under 104` | Socket path is 104 bytes or more. |
| (stderr prefix) | `stenographer: <description>` | Written by `current` before exit 78. |

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source reads no feature flag; `STENOGRAPHER_INSTANCE` selects an instance, it does not toggle a feature.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data collected**: None. The type reads definition files that hold an instance name, a data-root path and a port.
- **Storage**: None written by this type; definition files are written by `scripts/stenographer_instance.py`.
- **Transmission**: None; nothing leaves the process except the stderr line on a failed `current`.
- **Retention**: Not applicable: the type keeps only the resolved value in memory for the life of the process.

## Logging

The type uses no logging framework. Its one output is the line `current` writes to standard error before exiting with status 78.

| Event | Level | Message |
|-------|-------|---------|
| `current` failed to resolve | stderr (error) | `stenographer: <ResolutionError description>` |

## Platform Notes

- **SwiftUI**: Source is `Core/Stenographer/StenographerInstance.swift`, importing only `Foundation`. It uses Swift Regex (`wholeMatch(of:)` with a regex literal), `JSONDecoder` with synthesized `Codable`, `FileManager.default` for existence, listing and `destinationOfSymbolicLink(atPath:)`, the C `realpath(3)` freed with `free`, and a `static let` closure for the once-per-process `current`, which calls `exit(78)` on failure. Nothing is SwiftUI-specific.
- **Compose**: Use a Kotlin `data class Definition` with `kotlinx.serialization`, a sealed class for `ResolutionError`, `Regex("[a-z0-9][a-z0-9-]{0,31}").matches(name)`, `java.nio.file.Path.toRealPath()` for existing prefixes and `Files.readSymbolicLink` for dangling ones, and `by lazy` for `current`. Android apps have no launchd, user `Library` or Unix-socket path limit of 104, so the protected roots and socket check would be redefined against `Context.filesDir`.
- **React/Web**: Under Node, `JSON.parse` with explicit checks that all three fields are present and typed (it does not reject missing keys the way `Codable` does), `fs.existsSync`, `fs.readdirSync` sorted by name, `fs.realpathSync` for existing prefixes and `fs.readlinkSync` for dangling links, `process.env` and `process.argv` for selection, and `process.exit(78)` with `process.stderr.write`. A browser has no file system or process, so only the selection rule and the name and port validation translate.
- **AppKit / UIKit**: Same source on macOS. On iOS there is no launchd, no shared `~/Library/Application Support` across apps and no second daemon copy, so the named-instance mechanism has no counterpart; the default-instance values translate as constants.
- **WinUI 3**: Model `Definition` as a C# `record Definition(string Name, string DataRoot, int HttpPort)` deserialised with `System.Text.Json` (`JsonSerializer.Deserialize<Definition>` with `JsonNamingPolicy.CamelCase` so the keys stay `name`, `dataRoot`, `httpPort`, and `required` members so a missing key throws), and `ResolutionError` as an exception hierarchy or a discriminated `record` set with `ToString()` returning the same messages. Read selection from `Environment.GetEnvironmentVariable("STENOGRAPHER_INSTANCE")` and `Environment.GetCommandLineArgs()`. Put the definitions directory under `Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData)` (or `Windows.Storage.ApplicationData.Current.LocalFolder` for a packaged app) and replace the protected roots with the installed copy's `%APPDATA%` and log folders. Use `System.Text.RegularExpressions.Regex` with `^...$` anchors for the name. Canonicalise with `Path.GetFullPath` plus `FileSystemInfo.ResolveLinkTarget(returnFinalTarget: true)` for links, and compare with `StringComparison.OrdinalIgnoreCase` since NTFS is case-insensitive; the `/System/Volumes/Data` firmlink rule has no Windows counterpart. Windows supports `AF_UNIX` with a 108-byte `sun_path`, so the socket limit changes; a named pipe needs none. Implement `current` as a `static readonly Lazy<StenographerInstance>` that writes to `Console.Error` and calls `Environment.Exit(78)`; for a Windows service, a non-crash exit code likewise avoids the service manager's failure-restart action.

<!-- No `## Reference Implementations` section is authored. Record the code that implements this
ingredient with `cookr implements <uuid|rdid> <location> --platform <p>` and `cookr confirm <uuid|rdid>`;
a compiled doc or skill shows those rows as a derived section here. -->

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerInstance.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: A named instance exists only if its definition file does, and asking for a name with no definition is a hard error.
**Rationale**: The type's doc comment states that creating an empty store for a typo would look like data loss. Refusing with `undefined`, which names the expected path and the command that creates it, makes the typo visible.
**Approved**: pending

**Decision**: The environment variable wins over the `-instance` argument, and a present but empty variable selects the default.
**Rationale**: The doc comment on `requestedName` states that the daemon and the CLI are selected by environment and that an app passes its own selection to the daemon the same way, so the environment is the authoritative channel. The empty-value rule follows from the source checking for the key before its value.
**Approved**: pending

**Decision**: Reserved names and ports are fixed sets: names `usagewidget`, `instances` and `daemon`; ports 22847, 22848 and 22849.
**Rationale**: The doc comments on `reservedNames` and `reservedHTTPPorts` give each reason: the label `<baseLabel>.<name>` is already taken by the usage widget, the definitions directory and the installed daemon's launch-throttle identifier (whose `/tmp/<identifier>.launches` an instance's app guard would share), and the ports belong to the installed daemon, the installed account router and the retired Kitchen daemon adkd that an installed Kitchen may still run.
**Approved**: pending

**Decision**: A named instance's data root may not equal, contain or lie inside anything the installed copy owns: the current and legacy data roots, the current and legacy logs, and `~/.claude`.
**Rationale**: The doc comment on `protectedRoots` lists these, and `~/.claude` holds the hook socket, the drop directory and `settings.json`. A named instance is a development copy, and the guard keeps it from writing into the installed copy's state.
**Approved**: pending

**Decision**: Two named definitions may not share or nest data roots.
**Rationale**: The comment in `validate` states that each instance's lock is keyed on its own label, so nothing else stops two definitions that share a data root from running on one set of databases.
**Approved**: pending

**Decision**: Paths are compared after Python `os.path.realpath`-style canonicalisation, lowercased, with a leading `/System/Volumes/Data` dropped before and after resolving, and dangling symlinks followed.
**Rationale**: The doc comment on `canonicalComponents` states the rules match what `check_definition` in `scripts/stenographer_instance.py` uses, so the script and the Swift resolver refuse the same definitions. Lowercasing reflects the case-insensitive default APFS volume, and the firmlink rule reflects that `/System/Volumes/Data` reaches the same files while realpath keeps it as written. The dangling-link branch exists because `realpath(3)` fails on a dangling link where `os.path.realpath` follows it, per the comment in `canonicalPath`; the 32-link depth bound keeps a cycle finite.
**Approved**: pending

**Decision**: A peer definition that cannot be read is skipped in the overlap check rather than failing the instance being resolved.
**Rationale**: The doc comment on `otherDefinitions` states that one that cannot be read is resolved, and refused, on its own, so a broken sibling file does not block every other instance.
**Approved**: pending

**Decision**: A process whose instance cannot be resolved exits with status 78 (`EX_CONFIG`) and the reason on stderr, rather than crashing.
**Rationale**: The doc comment on `current` states that a normal exit keeps launchd's `KeepAlive: {Crashed: true}` from relaunching the process into the same failure.
**Approved**: pending

**Decision**: The socket path `<dataRoot>/stenographer.sock` must be under 104 UTF-8 bytes.
**Rationale**: The doc comment on `socketPathLimit` states that `sockaddr_un.sun_path` is 104 bytes on Darwin including the NUL, so a longer path could not be bound; refusing at definition time surfaces this before the daemon starts.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |

`separation-of-concerns` passes because the type only selects, reads and validates an instance; writing definitions belongs to `scripts/stenographer_instance.py`, deriving labels, ports and paths for the rest of the product belongs to `StenographerIdentifiers`, and the passive gates belong to the daemon's `InstancePolicy` and the app's `StenographerInstances`. `unit-test-coverage` is partial because the only test in this repository, `StenographerInstancePortTests`, covers port uniqueness alone; the doc comment on `validate` names a shared fixture, `tests/fixtures/instance_definition_cases.json`, that is not present among these sources. `explicit-error-handling` passes because every refusal is a distinct `ResolutionError` case with its context, and `current` reports the error before a deliberate exit. `input-sanitization` passes: names, data roots, ports, overlaps, a port another named definition holds, and socket length are all checked. `data-integrity` passes because a named data root can never equal, contain or sit inside the installed copy's data or another instance's, compared after symlink, case and firmlink canonicalisation. `safe-defaults` passes because no selection means the installed default, and an unknown name is refused instead of creating an empty store.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-21 | Mike Fullerton | Resolved port-unique-across-instances: validate throws portTakenByAnotherInstance for a port another definition holds, checked after the instance overlap; added its description and vectors 041 to 044. |
