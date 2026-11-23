
- **Null / empty input**: No chat named with exactly one chat resolves to that chat; with none it answers "There is no Terminal Chat open." (MUST). An empty command on run is refused (MUST). A missing `lines` means 40 (MUST).
- **Boundary values**: Settle below 0.1 seconds becomes 0.1, above 60 becomes 60; timeout above 600 becomes 600 (MUST). A chat id prefix that matches two chats is refused with the matching ids (MUST). `lines` is not clamped by the server; the session floors it at 1 and returns at most the screen's lines (`lines-bounds`).
- **Concurrent access**: The directory and the server are main-actor only; the chats read at the start of a request are held strongly for that request, so a chat released meanwhile still answers from that snapshot and drops from the next listing (MUST). Two simultaneous requests each run through the main actor in turn, and the transport answers each connection on its own task.
- **Error states**: A malformed request, an unknown chat, an unconnected chat, an empty command and a failed encode each give an error answer rather than a dropped connection, except an oversize request, which is dropped (MUST).
- **Offline / disconnected state**: Not applicable: the channel is a local socket, not a network. A client whose app is not running finds no socket for a live process; a stale socket file from a dead process is removed when the directory is prepared (MUST).
- **Unconnected private chat**: The chat is listed, with `connected` false and its project and directory as given, because there is no terminal to present them; the source comment says nothing is listed for such a chat, but the code lists it, so a port MUST follow the code's behavior.
- **Server restart**: `stop()` then `start()` makes a new listener at the same path; whatever file is at the path is removed first.
- **Long commands**: A command that outlasts the timeout is reported by the session as still running; `wait` then returns more output (MUST, per the session's own contract).
- **Shutdown during a request**: The request is answered with "The app is shutting down." (MUST).

