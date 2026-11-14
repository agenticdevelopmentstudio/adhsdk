
- **Data collected**: The bytes of a terminal stream (keystrokes, pastes, replies and program output), which can include secrets, and the privacy words.
- **Storage**: In memory only: the filter, the two streams and their held bytes. The engine's buffer and scrollback hold the concealed text, so the real text of a concealed word is never stored there.
- **Transmission**: None by the view. Revealed input goes to the local shell process; concealed output goes to the parser.
- **Retention**: Held bytes live until the next send or read, the flush timer or a change of words; the filter lives as long as the view or until replaced.
- **Purpose**: Letting the user and anything that reads the terminal from outside see aliases while the shell works with the real text.

