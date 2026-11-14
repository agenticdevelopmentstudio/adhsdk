
The type module that defines the one agent-ready digest of the whole fleet. `GET /report` and the MCP tool `get_report` both return a `ReportResponse`, and both accept a `ReportParams` query. The module holds declarations and three constants (`REPORT_SCHEMA`, `SEVERITIES`, `REPORT_SOURCES`). Every judgement in the payload (verdict, severity, order, staleness, completeness) is made on the server by the report rules; a client formats and lays out, and decides nothing. The payload carries a `schema` string, and a change a reader must adapt to is a new `status.report/N`.

A port reproduces these shapes exactly, because the CLI, the MCP clients and any agent parse them. The producers (`buildReport` and `parseReportParams`) are specified by their own recipes; this recipe is the contract they meet.

