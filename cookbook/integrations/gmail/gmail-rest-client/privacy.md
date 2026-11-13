
- **Data collected**: The client handles the user's Gmail data (message ids, thread and message contents, labels, the address from `profile`) and a bearer token that grants access to it; it collects nothing beyond what an operation returns.
- **Storage**: None. The token and every response are held only for the duration of a call; the client has no cache, file or database. Where results and tokens are stored is for the callers (the Keychain and the mail store are separate components).
- **Transmission**: Every request goes over HTTPS to `gmail.googleapis.com` with the token in the `Authorization` header and no other third party. A `q` search string and label ids are sent in the URL query, and message ids in the path.
- **Retention**: None in this client. It writes no log, so tokens and message text do not appear in any log it produces.

