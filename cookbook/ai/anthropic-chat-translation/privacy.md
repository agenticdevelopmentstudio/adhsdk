
- **Data collected**: The component sees prompts, system text, tool arguments and results, image data (including base64 images, copied into `data:` URLs) and reply text. It records none of it.
- **Storage**: None; in memory for one call, or for one response in the stream translator's buffer.
- **Transmission**: The component sends nothing; the caller sends the translated body to the provider, so everything translated reaches the provider the caller chooses. No credential is read or written.
- **Retention**: None beyond the instance's life. Provider error bodies can carry text the provider chose to include and are passed on, truncated to 500 characters when they have no message field.

