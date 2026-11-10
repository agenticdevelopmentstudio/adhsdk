
- **Data collected**: None originates in this component. Transport does not
  read, store, or generate the `Authorization` bearer token; it only carries
  whatever header the caller's attached `ClientMiddleware` (outside this
  component's file set — `AuthenticationMiddleware`/`SessionRefreshMiddleware`
  in `Sources/Auth/`) has already added to the request, verbatim, to
  whichever URL `serverURL` resolves to. Token lifetime, storage, and
  revocation are that middleware/`CredentialStore`'s responsibility, not
  this component's.
- **Storage**: None. `APITransport`/`TransportResolver` hold only an
  in-memory `URL`/`ClientTransport` pair and a cached `TransportKind`;
  nothing here persists to disk.
- **Transmission**: The Direct path transmits over HTTPS to
  `DaemonContract.backendURL`. The Daemon path transmits over plain HTTP,
  but only to `127.0.0.1` (loopback per `daemonURL(port:)`), so those bytes
  never leave the device.
- **Retention**: None beyond the lifetime of the `URLSession` in use. The
  daemon path's session is `.ephemeral` (no shared cache or cookies, per
  daemon-session-is-ephemeral); the direct path's session is
  swift-openapi-urlsession's default `URLSessionTransport()`, whose
  retention this component does not further constrain.

