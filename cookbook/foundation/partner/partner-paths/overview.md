
`PartnerPaths` is a value type that answers one question: where the partner keeps its files. Given a home directory and the app's storage token it derives the partner directory, the MCP config file, the system prompt file, the jobs and reviews directories, the shared Claude skills directory and the skill file for a job. It performs no file access; it only builds locations.

