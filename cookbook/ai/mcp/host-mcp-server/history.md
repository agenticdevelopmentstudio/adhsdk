
| Version | Date | Author | Summary |
| 1.3.0 | 2026-11-25 | Mike Fullerton | serve(over:) and stop() are queued in call order (serve-serialized); the last call wins and a thrown serve does not block the queue. |
|---------|------|--------|---------|
| 1.2.0 | 2026-11-25 | Mike Fullerton | Added the AgentToolSource bridge: exposes AgentTools to the host MCP server with a fixed caller; header text corrected to X-ADHD-Pane. |
| 1.1.0 | 2026-11-23 | Mike Fullerton | Apps suite Phase 4: callerHeader is X-ADHD-Pane; legacyCallerHeader and callerHeaders added. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (HostMCPServerConformanceTests.swift, 14 new vectors; 24 of 25 covered with HostMCPServerTests); unit-test-coverage now partial (host-mcp-server-022 skipped: Logger not capturable). |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
