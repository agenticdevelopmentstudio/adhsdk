
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

