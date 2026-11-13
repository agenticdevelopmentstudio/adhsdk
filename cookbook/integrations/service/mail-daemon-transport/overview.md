
`MailDaemonTransport` is a caseless enum of static members that turns a host's IPC call into a `MailClient` ([adhsdk.ingredient.integrations.service.mail-rpc](cookbook:fc9671be-170c-436e-9628-892624952191)) for a mail service running in a daemon (`MailIntegrationService`, [adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)). A host app and its command-line tool both build their client through it, so the deadline, the no-retry rule, the empty-reply check and the failure wording live in one place whatever the IPC mechanism is. The host supplies the IPC round trip and an error classifier; the transport supplies the rules around them.

It declares one public error type, `MailTransportFailure` (`timedOut`, `connectionDropped`, `unreachable(String)`), which the host maps its own IPC errors onto. Every failure surfaces to the caller as `MailClientError.remote(String)`, an error type of the mail-rpc recipe.

