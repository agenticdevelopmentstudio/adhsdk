
- **Data collected**: none of its own; it writes whatever envelope the caller passes, which the hook capture command fills with the hook payload, account names and process context.
- **Storage**: one JSON file per call in the drop directory, with default file-system permissions; the source sets no restrictive mode and applies no encryption.
- **Transmission**: none; the file stays on the machine.
- **Retention**: the component never deletes a file; the daemon that scans the directory owns removal, and a `.tmp` leftover is never removed by this code.

