
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| stateStore | pane state store | required | Where the remembered pane identifier is kept, under the key "connectedPane". |
| directory | terminal chat directory, optional | none | Where the chat lists its session for processes outside the app to drive; none keeps it private. |
| listing | directory listing, optional | none | The identity the session is listed under; both directory and listing are needed for the session to be listed. |
| session | terminal chat session | created per instance | Read-only; what a persona chat uses to drive this chat's terminal. |

