
- **Data collected**: The message text itself is not collected by the component; it is passed to the onSend callback. The caller is responsible for handling the text (sending, storing, etc.).
- **Storage**: No data is stored persistently by the component. Text in the input field is held in memory only.
- **Transmission**: No data is transmitted by the component itself. The caller determines whether and how to send the message.
- **Retention**: Text is cleared from the input field after send. No logs or history are maintained by the component.

