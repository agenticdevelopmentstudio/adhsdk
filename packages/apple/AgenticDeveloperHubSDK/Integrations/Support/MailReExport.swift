// The mail vocabulary (MailClient, MailRequest, MailResponse, MailSource and
// the records they carry) lives in AgenticDeveloperHubSDKMail so iOS can link
// it without Integrations. Re-exported here so macOS call sites that import
// Integrations keep resolving it.
@_exported import AgenticDeveloperHubSDKMail
