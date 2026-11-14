
`Digest.hexString` is a public computed property added to every CryptoKit `Digest` (SHA-256, SHA-1, MD5 and the rest). It renders the digest's bytes as a lowercase hexadecimal string, two digits per byte, and gives every caller that stores a digest as text the same spelling. Keeping the rendering in one place means two hashes of the same bytes compare equal as strings.

