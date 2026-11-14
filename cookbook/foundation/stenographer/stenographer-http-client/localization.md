
Not applicable: the client defines no user-facing string of its own. The only text it produces is the fallback `reason` `HTTP <status>` carried in `SummarizeDaemonFailure` and `OversightActResultDTO`, which is an English diagnostic and not a localized string; every other message is the daemon's own text passed through.

