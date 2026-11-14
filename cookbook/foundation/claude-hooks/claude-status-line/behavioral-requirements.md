
### Layout

- **directory-layout**: The dispatcher directory MUST be `claudehelpers/statusline` under the Claude directory, with the dispatcher at `dispatch.sh`, entries under `renderers/` and `taps/`, and failure records under `errors/`.
- **dispatcher-command**: `dispatcherCommand` MUST be `sh ` plus the dispatcher path (shell-quoted only when needed, matching Python's `shlex.quote`) plus ` # claudehelpers-statusline`, byte for byte the string claudehelpers' Python implementation writes, so the two never fight over the slot. For a dispatcher at `/Users/me/.claude/claudehelpers/statusline/dispatch.sh` the string is `sh /Users/me/.claude/claudehelpers/statusline/dispatch.sh # claudehelpers-statusline`.
- **settings-lock-name**: The shared lock name MUST be `.settings.lock`, the lock every `settings.json` editor that follows the contract holds across its read-modify-write.

### Recognising commands and names

- **dispatcher-command-shape**: `isDispatcherCommand(_:)` MUST be true for a trimmed command that starts with `sh `, ends with ` # claudehelpers-statusline` and has a non-empty path between, whichever directory it runs from, and false for a command that only mentions the marker elsewhere (such a command is some tool's own).
- **adopted-name**: `isAdoptedName(_:)` MUST be true for `adopted` and for `adopted-` followed by one or more ASCII digits, and false for any other name, including one that merely starts with the word (`adoptedtheme`) and one with an empty or non-numeric suffix.
- **valid-name**: `isValidName(_:)` MUST accept only a non-empty name whose first character is an ASCII letter or digit and whose every character is an ASCII letter, digit, `.`, `_` or `-`.
- **dispatcher-version**: `dispatcherVersion(_:)` MUST return the integer on the first line of the form `# claudehelpers-statusline-dispatch <N>` whose remainder, after trimming spaces, is one or more ASCII digits, MUST skip a line with a non-numeric or empty remainder and keep looking, and MUST return nil when no line qualifies.

### Installing the dispatcher

- **install-writes-newer**: `installDispatcher()` MUST write the bundled dispatcher to `dispatch.sh` with mode `0755` when none is installed or the installed version is lower than the bundled version, and MUST report the installed and offered versions and that it wrote.
- **install-never-downgrades**: `installDispatcher()` MUST NOT write when the installed version is the same or newer, because a newer copy came from a newer tool that relies on it.
- **install-replaces-unversioned**: An installed copy with no version line MUST read as no installed version and be replaced.
- **install-missing-bundle**: When the bundled dispatcher is unreadable, `installDispatcher()` MUST return without writing and with no offered version if a versioned copy is installed, and MUST throw `dispatcherMissing` carrying the bundled path when none is.
- **install-unversioned-bundle**: When the bundled dispatcher has no version line, `installDispatcher()` MUST return without writing if a versioned copy is installed, and MUST throw `dispatcherUnversioned` carrying the bundled path when none is.

### Entries

- **entry-content**: An entry file MUST hold exactly its command followed by one newline, and `entries()` and `entry(named:)` MUST return the command with surrounding whitespace trimmed.
- **register-replaces**: `register(_:name:command:)` MUST write the entry under the requested kind, remove the same name from the other kind, and return true when it changed any file and false when the entry already held exactly that command and nothing was removed.
- **register-name-precondition**: `register` MUST fail a precondition on an invalid name.
- **unregister-both**: `unregister(_:)` MUST remove the name from both kinds and delete its recorded error, and MUST return true only when an entry was present. It does not validate the name, so callers pass only names they own or names read from `entries()` (see **own-name-only**).
- **entries-listing**: `entries()` MUST list `renderers` before `taps`, each in name order, and MUST skip names that are not valid and files that cannot be read as text.
- **entry-utf8**: An entry file that is not valid UTF-8 MUST read as absent, so `entries()` skips it and `entry(named:)` returns nil.
- **settings-lock-held**: Callers MUST hold the shared `.settings.lock` across any sequence that reads the slot and writes entries; the type takes no lock itself, and each write is atomic so a reader never sees a half-written entry.
- **own-name-only**: `register` and `unregister` MUST be called only with the calling tool's own name, or a name read from `entries()`; the one removal of another entry is **adopt-replaces-earlier**'s removal of earlier `adopted*` renderers.
- **entry-lookup**: `entry(named:)` MUST return nil for an invalid name and otherwise the first match, checking `renderers` before `taps`.

### Adoption

- **adopt-keeps-command**: `adopt(_:)` MUST keep a command found in the slot as a renderer under the first free name of `adopted`, `adopted-2`, `adopted-3` and so on, free meaning absent from both kinds, and MUST return the name used.
- **adopt-noop**: `adopt(_:)` MUST return nil and write nothing when the trimmed command is empty or when some entry of either kind already runs exactly that command.
- **adopt-replaces-earlier**: Before writing, `adopt(_:)` MUST remove every earlier renderer with an adopted name, because the slot holds one command and the one found there replaced whatever was adopted before, so no line the person replaced comes back.
- **adopt-spares-taps**: `adopt(_:)` MUST NOT remove a tap, even one with an adopted name.

### Failure record

- **last-error**: `lastError(of:)` MUST return the trimmed text of `errors/<name>`, and nil when the name is invalid, the file is missing or unreadable, or the trimmed text is empty.
- **error-record-meaning**: This is a note on the dispatcher's contract, not behavior of this type: the dispatcher writes `errors/<name>` on a non-zero exit, a timeout or a failure to run, and deletes it when the entry next succeeds, so a record means "the entry is failing now and is missing from the line". This type only reads the record through **last-error**.
- **dispatcher-contract**: The dispatcher MUST run every renderer in name order and show its output; this type only supplies the files it reads and does not run them.

### Storage

- **owner-only-tree**: The tree MUST be owner-only because an adopted command may carry a token: directories `0700`, entries `0600`, each file created at its final mode before it becomes visible, through an atomic write. The one exception is the dispatcher `dispatch.sh`, which **install-writes-newer** writes at `0755` because it holds no secret and must be executable.
- **write-creates-parents**: Every write MUST create the entry's directory with intermediate directories and mode `0700` first.
- **write-failure-propagates**: A failed write or removal inside `installDispatcher`, `register`, `unregister` or `adopt` MUST throw to the caller.

### Errors

- **error-descriptions**: `Failure.dispatcherMissing` MUST describe "The status-line dispatcher this build carries is missing at <path>.", and `dispatcherUnversioned` MUST describe "The status-line dispatcher this build carries has no version line at <path>."
- **sendable-value**: The type MUST be a `Sendable` struct holding no mutable state; every call reads or writes the file system.
- **downward-dependencies**: The type MUST depend on nothing above `ShellQuoting` and `AtomicFile`.

