
- **Data collected**: Email address (required), name (optional, if collectName is true), page URL (sourceUrl).
- **Storage**: The component does not store data locally. Data is transmitted to the backend immediately upon submission.
- **Transmission**: Email, name, and sourceUrl are transmitted in a POST body via HTTP/HTTPS to the backend endpoint. The request includes the signed nonce for anti-abuse verification.
- **Retention**: Retention is determined by the backend list configuration and the hub. The component has no control over retention.
- **Honeypot**: The honeypot field's value is always sent to the backend as `website` — empty for a legitimate visitor, non-empty only if something else (a bot, or a password manager that ignored the opt-out) filled it in. The server's anti-abuse gate treats any non-empty value as a bot signal and silently rejects the submission without writing it; an empty value is never treated as suspicious.

