
- **Data collected**: Commands typed into a chat and the terminal's replies; the chat list with project and directory text.
- **Storage**: Nothing persisted by these types; the directory holds listings and weak session references in memory, and the socket file lives in the socket directory while the app runs.
- **Transmission**: Over a local Unix-domain socket to a process of the same user only; nothing leaves the machine.
- **Retention**: A request lives for one connection; the directory entry lives until removed or the session is released.
- **Concealment**: Project and directory text and terminal replies are passed through the connected terminal's presentable text, so a private terminal's privacy words replace the real ones, as on its screen.
- **Security**: The directory is owner-only (mode 0700) and the socket file owner-only (mode 0600), and a peer whose user id differs is refused, because a local HTTP port is open to every process on the machine; a request over 1 MiB is dropped; a stale socket from a dead process is removed. There are no tokens or sessions; authority is being the same user. See the open question on `caller-authorization`.

