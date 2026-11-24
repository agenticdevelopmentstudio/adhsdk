
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `inner` (parameter of `init(wrapping:)`) | `any Transport` | none — required | The transport that does the real reading and writing. |
| `deadline` (parameter of `waitUntilNothingOwed`) | `Duration` | none — required | The longest to wait for outstanding replies. |
| Stdio drain deadline | constant in the stdio serving path (`HostMCPServer.stdioDrainDeadline`) | 360 seconds | The deadline `serveUntilDrained` passes; owned by the caller, not by this type. |

