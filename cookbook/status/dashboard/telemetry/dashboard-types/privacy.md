
The module defines shapes that carry site hostnames, page paths, countries, referrers, device and browser names, error names and Vercel request ids. It stores and sends nothing itself. The source notes that PostHog error data holds no message text, only error names, and that runtime messages are cut to the first line, at most 200 characters. A request id (`sampleRequestId`) is a lookup handle in Vercel, not a user identifier.

