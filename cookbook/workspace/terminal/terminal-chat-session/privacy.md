
- **Data collected**: Everything typed into the terminal and everything it prints, passed through the chat as transcript events and returned strings.
- **Storage**: In memory only: the unsent events and up to 64 KiB of unclaimed output, until claimed or the chat is released; the transcript is the subscriber's.
- **Transmission**: None by this type; a persona's tool or the control server relays the strings it returns.
- **Retention**: Replies are retained as unclaimed output until a wait claims them, the chat is dropped, or the 64 KiB limit forces them out.
- **Concealment**: The session does no concealment of its own; a private terminal's screen, and its `presentable` text of the echo, are already concealed, and every reply is read off that screen.
- **Security**: Anyone with the session can type any command into the connected shell; the session performs no authorization.

