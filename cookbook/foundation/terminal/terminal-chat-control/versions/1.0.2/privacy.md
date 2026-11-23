
- **Data collected**: none by this code; a request carries a command the caller chose and a reply carries terminal output.
- **Storage**: sockets only, in an owner-only directory; nothing is written to disk but the socket files.
- **Transmission**: local only, over a Unix-domain socket reachable by this user alone; nothing leaves the machine.
- **Retention**: none defined by this code; the chat's transcript, outside these sources, records what was typed and printed.
- **Concealment**: output and the listed project and directory pass through the connected terminal's concealment, so a private terminal's privacy words replace its real ones.

