
`Digest.hexString` is a public computed property added to every CryptoKit `Digest` (SHA-256, SHA-1, MD5 and the rest). It renders the digest's bytes as a lowercase hexadecimal string, two digits per byte, and is the one place the daemon turns hash bytes into the hex strings it stores: `transcript_lines.line_hash` and `ConfigChange.file_sha256`. Keeping it in one place means every stored hash is spelled the same way, so two hashes of the same bytes compare equal as strings.

