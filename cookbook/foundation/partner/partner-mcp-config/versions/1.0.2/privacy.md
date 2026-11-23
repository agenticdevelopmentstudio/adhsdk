
- **Data collected**: None. The type receives a port, a token and a caller id from its caller.
- **Storage**: The bearer token is stored in clear text in the config file. The protection is the file system: the parent directory is 0700 and the file is 0600, so only the owning user can read it. The source does not encrypt the file or keep the token in a keychain.
- **Transmission**: The token is not sent by this type. The partner's `claude` reads the file and sends the token in the `Authorization` header to `127.0.0.1`, so it stays on the machine. The transport is plain `http` on the loopback address, with no TLS.
- **Retention**: The file stays on disk until something removes or replaces it; `write` replaces it on each partner start. Token lifetime and revocation belong to the MCP endpoint that issues the token, not to this type.

