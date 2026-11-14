
- **SwiftUI**: The component imports only `CryptoKit` and `Foundation`, has no UI dependency, and so is the same on AppKit and UIKit; a SwiftUI view calls `hexString` on any digest.
- **Compose**: Hash with `java.security.MessageDigest` and render with `joinToString("") { "%02x".format(it) }` (a boxed `Byte` already formats as two unsigned hex digits under `%x`, so no mask is needed), or `HexFormat.of().formatHex(bytes)` on JDK 17, which is lowercase by default.
- **React/Web**: Hash with `crypto.subtle.digest("SHA-256", data)` and render with `Array.from(new Uint8Array(buf), b => b.toString(16).padStart(2, "0")).join("")`; `toString(16)` is lowercase and `padStart(2, "0")` keeps the leading zero. In Node, `createHash("sha256").update(data).digest("hex")` is the same string.
- **AppKit / UIKit**: Same as the SwiftUI note: CryptoKit is the same on both.
- **WinUI 3**: Use `System.Security.Cryptography` (`SHA256.HashData(bytes)`, which returns `byte[]`) and render with `Convert.ToHexString(hash).ToLowerInvariant()` (.NET 5 and later; `Convert.ToHexString` is upper-case, so the `ToLowerInvariant` call is required) or `string.Concat(hash.Select(b => b.ToString("x2")))`. Put it in a static extension class over `byte[]` rather than over a digest type, since .NET hash APIs return a plain byte array and have no `Digest` protocol.

