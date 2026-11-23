
Generation

- **generate-length**: `generate()` MUST return exactly 64 characters.
- **generate-alphabet**: Every character MUST be a hexadecimal digit, written as two lowercase digits per byte (`%02x`).
- **generate-entropy**: The 32 bytes MUST come from the system's secure random generator (`SecRandomCopyBytes` with the default generator), not from a pseudo-random generator seeded by the caller.
- **generate-fresh**: Two calls MUST NOT return the same token (`testGenerateIs64HexCharacters` asserts they differ).
- **generate-crash-on-failure**: If the secure random generator reports an error, `generate()` MUST stop the process with a precondition failure whose message names the status, and MUST NOT return a weaker token.

Loading an existing file

- **load-reads-existing**: When a regular file exists at the path and holds a non-empty token, `load(from:)` MUST return that token.
- **load-trims**: The returned token MUST be the file's content with leading and trailing whitespace and line feeds removed.
- **load-stable**: Loading the same path twice MUST return the same token.
- **load-no-format-check**: `load(from:)` MUST NOT check that an existing token is 64 hexadecimal characters; any non-empty text is returned (the test keeps the token `keepme`).
- **load-tightens**: When an existing file has any group or other permission bit set, `load(from:)` MUST set its mode to 0600 and keep its token.
- **load-leaves-narrow**: When an existing file's mode has no group or other bit set, `load(from:)` MUST NOT change its permissions.
- **load-directory-mode**: `load(from:)` MUST NOT change the mode of the directory that holds the file.

Creating the file

- **load-creates**: When nothing exists at the path, `load(from:)` MUST create the file with a freshly generated token and return it.
- **load-regenerates-empty**: When the file exists but is empty or holds only whitespace, `load(from:)` MUST treat it as no token, write a new token to the same path and return it.
- **load-creates-directory**: `load(from:)` MUST create the parent directory, including missing intermediate directories, before writing.
- **file-mode-created**: A newly written file MUST have mode 0600, and the mode MUST be set in the call that opens the file, so the file is never briefly wider.
- **file-no-newline**: The written file MUST hold the 64 characters as UTF-8 with no trailing line feed.
- **write-truncates**: When it writes over an existing empty file, the write MUST truncate it first.
- **write-no-follow**: The write MUST refuse to follow a symbolic link at the path, so a link planted after the check in `load(from:)` is refused rather than written through.
- **write-chmod**: After opening, the write MUST also set the descriptor's mode to 0600; the result of that call is not checked.

Refusing unsafe paths

- **refuse-non-regular**: When something exists at the path that is not a regular file (a symbolic link, directory, device or other), `load(from:)` MUST throw `LoadError.unreadable` and MUST NOT follow or read the target.
- **refuse-dangling-link**: A dangling symbolic link MUST be refused the same way, and nothing MUST be created at its target.
- **refuse-link-target-untouched**: The target of a refused symbolic link MUST be left unchanged.

Errors

- **error-unreadable**: Any failure while tightening or reading an existing file, or finding a non-regular file at the path, MUST be thrown as `LoadError.unreadable`, carrying the URL and the underlying error.
- **error-unwritable**: Any failure while creating the directory or writing the new file MUST be thrown as `LoadError.unwritable`, carrying the URL and the underlying error.
- **error-descriptions**: `LoadError` MUST provide a description `could not read <path>: <reason>` for the unreadable case and `could not write <path>: <reason>` for the unwritable case.
- **error-no-partial-token**: When `load(from:)` throws, it MUST NOT return a token, so a caller can use none in place of a token it could not keep.
- **concurrent-first-load**: NEEDS REVIEW: Not implemented in source. `load(from:)` checks the path, then writes it, with no lock and no exclusive-create flag (the write uses create and truncate), so two processes or threads that load a missing path at once can each write a different token and return a different one; a test or a decision about a lock or an exclusive-create open would settle it.

Security properties

- **token-lifetime**: The token MUST persist until its file is deleted; the source defines no expiry and no rotation.
- **token-revocation**: Deleting the file MUST cause the next `load(from:)` to create a new token; the source has no other revocation call, and processes already holding the old token are not told.
- **token-not-logged**: The component MUST NOT log or print the token; the source makes no log call.
- **violation-handling**: A symbolic link or other non-regular file at the path MUST be treated as a violation and refused with an error, never repaired or replaced.

