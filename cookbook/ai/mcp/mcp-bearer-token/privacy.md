
- **Data collected**: The bearer token, a random secret that identifies no person. It is the only credential this component handles.
- **Storage**: In a regular file at the caller's path, mode 0600 from creation, as plain text with no encryption and no Keychain use; the directory's mode is left as it was.
- **Transmission**: This component sends nothing. The token leaves the file when the app writes it into the registration command or into the environment of processes it hands the MCP URL to, and callers present it as a bearer header to the local endpoint.
- **Retention**: Until the file is deleted. The source defines no expiry and no rotation; deleting the file is the only revocation, and the next load creates a new token.

