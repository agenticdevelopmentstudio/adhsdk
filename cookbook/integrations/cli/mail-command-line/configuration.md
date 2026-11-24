
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `args` | `[String]` | required | The arguments after `mail`, such as `["list", "me@example.com", "--limit", "10"]` |
| `program` | `String` | `"mail"` | How the host's users type the command, used in the usage text |
| `client` | `MailClient` | required | The injected client that performs every operation; it owns transport, timeouts and retries |
| `stdout` | `@Sendable (String) -> Void` | required | Receives the result, or the usage text for a help request; one call per successful run |
| `stderr` | `@Sendable (String) -> Void` | required | Receives usage text for a usage error and `Error: ...` lines for failures |
| `--json` | flag | off | Emit the client's value as pretty printed, key-sorted JSON |
| `--limit` | positive integer | filter default 50 | Page size, clamped to 1 through 500 |
| `notFoundStatus` | `Int32` constant | 3 | Exit status when a message id matches nothing |

The component reads no environment variables, settings keys or files.

### Options accepted by each command

Value-taking options consume the next argument. Every command also accepts `--json`.

| Command | Value-taking options | Flags |
|---------|----------------------|-------|
| `accounts` | none | none |
| `labels` | none | none |
| `list` | `--since`, `--until`, `--label`, `--any-label`, `--limit`, `--cursor`, `--query` | `--bodies` |
| `get` | none | none |
| `thread` | none | `--bodies` |
| `label add`, `label remove` | none | none |
| `move` | `--to`, `--from` | none |

### Usage text

`usage(program:)` returns this text, with `{{program}}` replaced by `program` and `{{notFoundStatus}}` by 3. Lines are joined by a newline with no trailing newline.

```
usage: {{program}} <command> [--json]
  {{program}} accounts
  {{program}} labels <account>
  {{program}} list <account> [--since D] [--until D] [--label L]... [--any-label L]... [--limit N]
      [--cursor C] [--bodies] [--query Q]
  {{program}} get <account> <id>
  {{program}} thread <account> <id> [--bodies]
  {{program}} label add <account> <label> <id>...
  {{program}} label remove <account> <label> <id>...
  {{program}} move <account> <id>... --to <label> [--from <label>]...
D is YYYY-MM-DD or an ISO-8601 timestamp. L is a label id or exact name. An id is our
message id or Gmail's.
list: a message must carry every --label (AND) and, if any are given, at least one
  --any-label (OR); the two combine.
list --query: searches Gmail itself with Q in Gmail's search syntax ("from:greenhouse"),
  beyond the synced mail; --since, --until and --label narrow it, --any-label is refused
  (write {label:a label:b} in Q).
thread: the whole conversation from Gmail, oldest first; <id> is a thread id or the id of
  any message in it. A message you sent is marked (you).
move: adds the --to label and removes every --from label, in one Gmail write. With no
  --from it removes INBOX (nothing for --to INBOX).
exit status: 0 success, 1 failure, {{notFoundStatus}} a message id matches nothing, 64 usage error.
```
