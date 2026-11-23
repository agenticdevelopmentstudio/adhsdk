
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcp-registration-001 | channel-server-name, channel-port, channel-url | `Channel.dev` and `Channel.release` | `adhd-dev`, 22871, `http://127.0.0.1:22871/mcp`; `adhd`, 22850, `http://127.0.0.1:22850/mcp` (`MCPRegistrationTests.testEachChannelHasItsOwnNameAndPort`) |
| mcp-registration-002 | command-shape, entry-json, entry-no-token | `claudeCommand(channel: .dev, adhdPath: "/opt/adhd/adhd")` | Exactly `claude mcp add-json --scope user adhd-dev '{"headersHelper":"/opt/adhd/adhd mcp headers","type":"http","url":"http://127.0.0.1:22871/mcp"}'`, with no `Bearer` (`testClaudeCommandIsTheHeadersHelperForm`) |
| mcp-registration-003 | entry-path-quoting, command-shape | `entryJSON(channel: .release, adhdPath:)` with a path holding a space | `headersHelper` is `'<path>' mcp headers`; the command starts `claude mcp add-json --scope user adhd '` and contains `'\''` (`testAPathWithSpacesIsOneShellWordInTheHelper`) |
| mcp-registration-004 | registered-needs-server-entry, registered-url-equal | `{"mcpServers":{"adhd-dev":{"type":"http","url":"http://127.0.0.1:22871/mcp"}}}` | true for `.dev`, false for `.release` (`testRegisteredWhenTheEntryPointsAtTheChannel`) |
| mcp-registration-005 | registered-old-entry | `{"mcpServers":{"adkitchen":{"type":"http","url":"http://127.0.0.1:22871/mcp"}}}` | false for `.dev` (`testTheOldKitchenEntryIsNotARegistration`) |
| mcp-registration-006 | registered-url-equal | An `adhd-dev` entry whose url is `http://127.0.0.1:22850/mcp` | false for `.dev` (`testNotRegisteredWhenThePortDiffers`) |
| mcp-registration-007 | registered-failure-is-false | `/nonexistent/.claude.json`, then a file containing `not json` | false in both cases, with no thrown error (`testNotRegisteredWhenTheFileIsMissingOrNotJSON`) |
| mcp-registration-008 | registered-needs-server-entry | `{"mcpServers":{"adhd-dev":{"type":"http"}}}` | false, because the entry has no `url` (derived from the `guard`; no test) |
| mcp-registration-009 | registered-ignores-headers | An `adhd-dev` entry with the right `url` and any `headersHelper` | true (derived from the single `url` check; no test) |
