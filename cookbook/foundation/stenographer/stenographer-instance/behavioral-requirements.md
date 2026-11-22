
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

