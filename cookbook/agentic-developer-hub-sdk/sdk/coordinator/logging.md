
Not applicable: neither source file calls `os_log`, `Logger`, `print`, or
any other logging API. Failures are surfaced only through `InboundEvent`
values and thrown `PersonaChatError` values, never written to a log.

