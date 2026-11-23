
- **Data collected**: Commands typed into a chat and the terminal's replies; the chat list with project and directory text.
- **Storage**: Nothing persisted by these types; the directory holds listings and weak session references in memory.
- **Transmission**: In process, to the MCP host that serves the tools; the host decides who may call (a bearer token on a loopback port for adhd and the app's endpoint).
- **Retention**: A call lives for its duration; the directory entry lives until removed or the session is released.
- **Concealment**: Project and directory text and terminal replies are passed through the connected terminal's presentable text, so a private terminal's privacy words replace the real ones, as on its screen.
- **Security**: The tool source has no authority check of its own; see the open question on `caller-authorization`.
