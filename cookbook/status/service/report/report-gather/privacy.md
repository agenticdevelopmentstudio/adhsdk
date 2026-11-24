
- **Data collected**: None collected by this module. It carries commit messages, deploy error text, provider log tails and error groups from its sources into the report.
- **Storage**: None. Nothing is persisted; the report is built per call.
- **Transmission**: The report goes to the caller of `/report` or `get_report`. `deployLog` reads provider logs through `fetchDeploymentLog`, which uses the provider connection held in the app's storage and config; no token is added to the payload by this module.
- **Retention**: None.

Log tails are passed through as read. The module does no redaction.

