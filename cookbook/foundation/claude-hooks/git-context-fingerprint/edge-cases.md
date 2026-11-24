
- Null and empty input: a nil directory samples the inherited directory (`sample-directory-scope`); an empty payload is not a JSON object and returns unchanged (`enrich-fallback`); an empty object `{}` gets the fingerprint with no leading comma (`enrich-empty-object`).
- Malformed input: a payload that is not a JSON object returns unchanged (`enrich-fallback`); a payload whose `cwd` is not a string falls back to `workspace.current_dir` (`enrich-directory`); a payload whose top level is an array returns unchanged (`enrich-fallback`).
- Boundary values: a repository with fewer than five commits lists those it has; a repository with no commits has no `HEAD` to abbreviate, so the branch lookup fails and the sample is nil (`sample-nil-outside-repo`).
- Concurrent access: the type holds no state, so concurrent calls are independent; two samples of a moving tree may differ, and that is the point.
- Error states: an unreadable branch gives nil, never a thrown error (`sample-nil-outside-repo`); a failed status or log command after the branch resolved is silently read as empty, see the open question on `sample-subcommand-failure`.
- Trailing content: whitespace after the payload's last `}` is preserved by the splice (`enrich-splice`); a `}` inside a string value does not matter because the last `}` of a parsed object always closes it.
- Offline or disconnected state: not applicable; the commands read the local repository only.
- Exotic paths: non-ASCII file names are escaped identically across machines by the pinned `core.quotePath=true`, and signed commits do not add signature text to the log (`sample-config-pinned`).
- Hashing: the hash input is the exact text counted, so a status text with a trailing newline hashes with it (`sample-counts-characters`).

