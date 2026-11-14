
- **Data collected**: The bearer token, a credential that authorises calls to the local endpoint, is embedded in the command text `claudeCommand` returns.
- **Storage**: This component stores nothing. Running the returned command makes Claude Code store the token default inside its own configuration file (the file `isRegistered` reads); that storage is outside this source.
- **Transmission**: The command is returned as text; whatever shows or copies it (the caller) decides where it goes. `isRegistered` reads one local file and sends nothing.
- **Retention**: Not defined here. The token has no expiry or rotation in this component; its lifecycle belongs to the token's owner, `MCPBearerToken`.
- **Token in the command line**: The token appears in cleartext in the command string, so a shell's history or a clipboard may retain it. The source does not mask it.

