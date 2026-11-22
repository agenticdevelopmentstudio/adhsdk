
- **Data collected**: None. The type reads definition files that hold an instance name, a data-root path and a port.
- **Storage**: None written by this type; definition files are written by `scripts/stenographer_instance.py`.
- **Transmission**: None; nothing leaves the process except the stderr line on a failed `current`.
- **Retention**: Not applicable: the type keeps only the resolved value in memory for the life of the process.

