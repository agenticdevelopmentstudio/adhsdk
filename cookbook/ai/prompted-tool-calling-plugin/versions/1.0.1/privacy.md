
- **Data collected**: The conversation, the tool descriptions, the tool arguments and the tool results all pass through it; arguments and results are written into the prompt text sent to the provider.
- **Storage**: It stores nothing durable. A decoder holds the reply text in memory until it ends.
- **Transmission**: It transmits nothing itself; the wrapped plugin's request carries the rewritten messages and prompt to the provider, so tool results leave the app as prompt text exactly as ordinary messages would.
- **Retention**: A decoder's reply is discarded with the decoder.
- **Tool results as text**: Because results become user-message text, whatever a tool returns is visible to the provider, as with any message.

