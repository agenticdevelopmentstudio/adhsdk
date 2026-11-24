
The failure sentences are hardcoded English in `remoteError` and `send` and are not externalised; a host that localizes would have to replace them.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline) | `<daemonName> did not answer within 360 s` | `timedOut` |
| none (inline) | `cannot reach <daemonName>: the connection was refused or dropped (is <daemonName> running, and signed by the same team as this tool?)` | `connectionDropped` |
| none (inline) | `cannot reach <daemonName>: <detail>` | `unreachable` |
| none (inline) | `<daemonName> dropped the reply` | empty reply in `send` |

