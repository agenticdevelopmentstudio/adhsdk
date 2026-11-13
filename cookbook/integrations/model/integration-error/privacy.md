
Not applicable as collection: the type stores nothing and sends nothing. Payloads can carry an account email (`unknownAccount`) or Gmail's reply text (`gmail`), and `MailIntegrationService` stores the description as the connection's `lastError`, so a port should treat a payload as user data.

