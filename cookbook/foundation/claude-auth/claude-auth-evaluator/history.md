
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-11-21 | Mike Fullerton | Resolved duplicate-login-in-one-round (new refresh-once-per-token: one refresh per distinct refresh token per round, shared by every copy) and publish-permissions-failure (0600 is set on a temporary file before it replaces the old one, and a failure throws and publishes nothing); added vectors 057 to 062. |
| 1.1.0 | 2026-11-21 | Mike Fullerton | Covers ClaudeTokenRefresher and AccountFingerprints alongside the evaluator; drops the authored Reference Implementations section |
| 1.0.0 | 2026-11-21 | Mike Fullerton | Initial creation |
