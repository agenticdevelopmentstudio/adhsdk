
Vectors 001 and 002 are asserted in `PartnerProcessConfigurationTests`; the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-mcp-config-001 | write-temp-mode, write-overwrite-mode, json-headers, json-url | `write(port: 51477, token: "tok", callerID: "c1", to: <new file>)` (`mcpConfigWritesHeadersAndMode0600`) | File mode is 0600; text contains `"X-ADKitchen-Pane":"c1"` and `http://127.0.0.1:51477/mcp` |
| partner-mcp-config-002 | write-parent-tightened, write-overwrite-mode, write-no-residue | Parent directory 0755 holding `mcp.json` with content `old`, mode 0644; `write(port: 1, token: "new", callerID: "c1", to: mcp.json)` (`mcpConfigOverwritesLooseFileAndSecuresDirectory`) | File mode 0600; directory mode 0700; content contains `new`; directory listing is exactly `["mcp.json"]` |
| partner-mcp-config-003 | json-shape, json-type, json-sorted-keys, json-compact, json-unescaped-slashes | `json(port: 8080, token: "t", callerID: "c")` | `{"mcpServers":{"adkitchen":{"headers":{"Authorization":"Bearer t","X-ADKitchen-Pane":"c"},"type":"http","url":"http://127.0.0.1:8080/mcp"}}}` |
| partner-mcp-config-004 | server-name, caller-header-name | Read `serverName` and `callerHeader` | `adkitchen` and `X-ADKitchen-Pane` |
| partner-mcp-config-005 | json-sorted-keys, json-pure | Call `json` twice with the same arguments | The two results are byte-identical |
| partner-mcp-config-006 | json-no-validation | `json(port: 0, token: "", callerID: "")` | Url is `http://127.0.0.1:0/mcp`; `Authorization` is `Bearer ` (with trailing space); `X-ADKitchen-Pane` is the empty string; nothing is thrown |
| partner-mcp-config-007 | json-no-validation | `json(port: 1, token: "a\"b", callerID: "c")` | The token appears JSON-escaped as `Bearer a\"b`; the result parses back to `Bearer a"b` |
| partner-mcp-config-008 | json-url | `json(port: 65535, token: "t", callerID: "c")` | Url is `http://127.0.0.1:65535/mcp` |
| partner-mcp-config-009 | write-parent-directory | Target in a directory that does not exist, nested two levels deep | Both levels are created; the immediate parent has mode 0700 |
| partner-mcp-config-010 | write-content | Write, then read the file | The bytes equal `json` for the same arguments |
| partner-mcp-config-011 | write-errors-propagate | Target whose parent directory belongs to another user, so `setAttributes` fails | The call throws the `setAttributes` error unchanged; no file appears at the target |
| partner-mcp-config-012 | write-cleanup, write-rename-failure | Target path that is an existing non-empty directory, so `rename` fails | `CocoaError(.fileWriteUnknown)` is thrown; no `.tmp` file remains in the parent |
| partner-mcp-config-013 | write-temp-sibling | Write twice to the same target in a row | Both succeed; the second replaces the first; no temp name collides |
| partner-mcp-config-014 | write-atomic-rename | Write once, open a handle on the target, then write again to the same target | The target now holds the complete new JSON in a different file (inode); the earlier handle still reads the complete old content |

