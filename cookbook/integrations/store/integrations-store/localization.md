
The store produces no user-facing text of its own. The one error it raises, `IntegrationError.unknownAccount`, carries only the account string; its sentence ("No connected account matches ...") is a hardcoded English `errorDescription` in `IntegrationError`, outside this component, and is not localized.

