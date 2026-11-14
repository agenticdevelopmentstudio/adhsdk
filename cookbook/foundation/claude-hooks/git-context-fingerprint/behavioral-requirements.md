
### Sampling

- **sample-nil-outside-repo**: `sample(directory:)` MUST return nil when the branch cannot be resolved (the directory is not a repository, or the lookup fails or is empty), because there is then no block in the prompt to fingerprint.
- **sample-fields**: A sample MUST be a dictionary of exactly these keys and JSON types: `branch` (string), `status_char_count` (integer), `status_entry_count` (integer), `status_sha256` (string), `recent_commits_char_count` (integer), `recent_commits_sha256` (string) and `sampled_at` (string).
- **sample-branch**: `branch` MUST be the trimmed abbreviated name of `HEAD`.
- **sample-directory-scope**: When a directory is given every command MUST run with `-C <directory>`, and when it is nil the commands MUST run against the inherited working directory.
- **sample-config-pinned**: The status and log commands MUST be pinned against user configuration (the branch lookup is not pinned) so the fingerprint moves when the tree moves and only then: status MUST use `core.quotePath=true`, `-unormal` (matching Claude Code's own block) and `--no-renames`; the log MUST use `log.showSignature=false`, `--oneline`, `--no-decorate` and a limit of `recentCommitCount`.
- **sample-status-untrimmed**: The status output MUST be read untrimmed, see Design Decisions.
- **sample-entry-count**: `status_entry_count` MUST be the number of non-empty lines of the status output, not the number of pieces after splitting on newline, which would count the empty string after the final newline.
- **sample-counts-characters**: The two character counts MUST be the character counts of the untrimmed status text and of the trimmed commit text, and each hash MUST be the lowercase hex SHA-256 of that same text's UTF-8 bytes.
- **sample-clean-tree**: A clean tree MUST give a status count of 0, an entry count of 0 and the SHA-256 of the empty string for `status_sha256`.
- **sample-sampled-at**: `sampled_at` MUST be the UTC time of the sample in the exact form `yyyy-MM-ddTHH:mm:ssZ` (no fractional seconds, a literal `Z`), so a consumer can tell a render-time sample from one taken later on the drop-file path.
- **sample-recent-count**: `recentCommitCount` MUST be 5, the number of commits Claude Code's block lists.
- **sample-subcommand-failure**: NEEDS REVIEW: Not implemented in source. When the branch resolves but the status or log command then fails, the failure (a non-zero exit, a timeout of five seconds in `ReadOnlyGit`, or output that is not valid UTF-8) yields the empty string, which is indistinguishable from a clean tree or an empty history, so the sample reports a clean tree with the empty-string hash and no signal that the sample is wrong.

### Enrichment

- **enrich-nesting**: `enriched(payload:)` MUST return the payload with the fingerprint nested under `payloadKey`, which MUST be `stenographer_git`, a namespaced key that cannot collide with a field Anthropic adds and that the shared schema's columns are keyed on.
- **enrich-fallback**: `enriched(payload:)` MUST return the payload byte for byte unchanged when it is not a JSON object, the directory is not a repository, the fingerprint is not a valid JSON object, or the fingerprint cannot be encoded, because enrichment is best effort and a fumbled sample must never cost the daemon the row it decorates.
- **enrich-directory**: The directory sampled MUST be the payload's top-level `cwd` when it is a string, else `workspace.current_dir`, else nil, so the sample cannot drift onto whatever directory the process inherited.
- **enrich-splice**: The original bytes MUST be spliced, never re-encoded: the text up to the payload's last `}` is kept, a comma is added when the object is not empty, then `"stenographer_git":` and the fingerprint's JSON, then the remainder from that `}` on.
- **enrich-empty-object**: An empty object `{}` MUST get the fingerprint with no leading comma.
- **enrich-valid-check**: `JSONSerialization.isValidJSONObject` MUST be checked before encoding rather than relying on `try?`, see Design Decisions.
- **enrich-encoding**: The fingerprint MUST be encoded with sorted keys, so the spliced text is stable.

