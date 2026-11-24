
The file holds user-facing English strings that are not localized: the three older-service messages, `unexpected response from the mail service`, and the `errorDescription` of `MailClientError`, which returns whatever message the service sent. The service's own failure messages (for example `Sign-in was cancelled`) are written outside this file. There is no string table or locale handling, and the source marks no string for translation.

