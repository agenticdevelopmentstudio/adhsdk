
The Email Signup Form is an embeddable React component that collects email addresses (and optionally names) for a waitlist or mailing list. It is designed for third-party websites: the component has no internal coupling to any backend other than two public endpoints (list configuration and signup submission) and can be embedded with only a public key and an API base URL. The form includes anti-abuse protection via a honeypot field and a server-side nonce aging mechanism, and communicates failures to developers through console logging rather than user-facing error details.

