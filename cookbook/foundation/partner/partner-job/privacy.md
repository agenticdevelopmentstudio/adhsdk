
- **Data collected**: Job names, guidelines text and step commands, all written by the app or the owner; commands may name repositories, models or branches.
- **Storage**: The types store nothing. The `PartnerStore` in the macOS layer persists a job as one row, with the steps encoded as JSON text.
- **Transmission**: The types transmit nothing. Guidelines and step commands are given to the partner process through the system prompt and job files by other types.
- **Retention**: Until the owner deletes the job or resets it to its default.

