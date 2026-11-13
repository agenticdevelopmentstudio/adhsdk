
Not applicable as collection: the type stores nothing and sends nothing. Payloads can carry an account email (`unknownAccount`) or Gmail's reply text (`gmail`), and [MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) stores the description as the connection's `lastError`, so a port SHOULD treat a payload as user data.

