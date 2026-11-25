import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

private let sshKeygenPath = "/usr/bin/ssh-keygen"
private let sshKeygenInstalled = FileManager.default.isExecutableFile(atPath: sshKeygenPath)

/// `GitClient.signatures(for:in:caller:)` against a real repository signed with an SSH key
/// generated into the temp dir (recipe `foundation/git/git-client`, "Signatures"). The key,
/// the allowed-signers file and the signing settings are the fixture's own; nothing reads
/// the user's keys or configuration.
@Suite("GitClient signatures", .serialized, .disabled(if: !sshKeygenInstalled, "ssh-keygen not installed"))
struct GitClientSignatureTests {
    private let client = GitClient(configuration: GitClientConfiguration(
        executableURL: GitTestRepository.gitURL,
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
    ))

    /// A fresh ed25519 key with no passphrase in `directory`; returns the private key's URL.
    private func makeKey(in directory: URL) async throws -> URL {
        let key = directory.appendingPathComponent("signing-key")
        let configuration = SubprocessChannel.Configuration(
            executableURL: URL(fileURLWithPath: sshKeygenPath),
            arguments: ["-q", "-t", "ed25519", "-N", "", "-C", "test@example.com", "-f", key.path],
            environment: [:],
            environmentPolicy: .mergeOverParent,
            currentDirectoryURL: directory
        )
        let result = try await SubprocessChannel.run(configuration, budget: GitTestRepository.budget)
        try #require(result.exitStatus == 0, "ssh-keygen failed: \(result.standardError)")
        return key
    }

    /// Signing with `key` set up in `repository`: `gpg.format=ssh`, `user.signingkey` and an
    /// allowed-signers file naming `test@example.com`.
    private func configureSigning(_ repository: GitTestRepository, key: URL, in directory: URL) async throws {
        let publicKey = try String(contentsOf: key.appendingPathExtension("pub"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let allowedSigners = directory.appendingPathComponent("allowed_signers")
        try "test@example.com namespaces=\"git\" \(publicKey)\n".write(to: allowedSigners, atomically: true,
                                                                       encoding: .utf8)
        try await repository.run(["config", "gpg.format", "ssh"])
        try await repository.run(["config", "user.signingkey", key.path])
        try await repository.run(["config", "gpg.ssh.allowedSignersFile", allowedSigners.path])
    }

    @Test("a signed commit reads .good with its signer, and an unsigned one .unsigned")
    func signedAndUnsigned() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-signature")
        defer { repository.tearDown() }
        let keys = FileManager.default.temporaryDirectory.appendingPathComponent("git-signature-keys-\(UUID())")
        try FileManager.default.createDirectory(at: keys, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: keys) }
        let key = try await makeKey(in: keys)
        try await configureSigning(repository, key: key, in: keys)

        try repository.write("one\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.run(["commit", "-q", "-S", "-m", "signed"])
        let signed = try await repository.sha("HEAD")
        try repository.write("two\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.run(["commit", "-q", "--no-gpg-sign", "-m", "unsigned"])
        let unsigned = try await repository.sha("HEAD")

        let signatures = try await client.signatures(for: [unsigned, signed], in: repository.root)
        #expect(signatures.count == 2)
        #expect(signatures[signed]?.status == .good)
        #expect(signatures[signed]?.signer == "test@example.com")
        #expect(signatures[signed]?.key?.hasPrefix("SHA256:") == true)
        #expect(signatures[unsigned] == GitSignature(status: .unsigned, signer: nil, key: nil))
    }

    @Test("no shas answer empty without running git, and a non-sha is refused before git runs")
    func emptyAndRefused() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-signature-refused")
        defer { repository.tearDown() }
        #expect(try await client.signatures(for: [], in: repository.root).isEmpty)
        await #expect(throws: GitClientError.self) {
            _ = try await client.signatures(for: ["--all"], in: repository.root)
        }
    }
}

/// A sha the repository does not have, such as a stash dropped from another terminal, is
/// skipped rather than failing the batch it shares with the visible rows. Needs no key.
@Suite("GitClient signatures, missing objects", .serialized)
struct GitClientSignatureMissingTests {
    private let client = GitClient(configuration: GitClientConfiguration(
        executableURL: GitTestRepository.gitURL,
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
    ))

    @Test("an unknown sha is absent from the answer and the other commits still answer")
    func unknownShaSkipped() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-signature-missing")
        defer { repository.tearDown() }
        try repository.write("one\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.run(["commit", "-q", "--no-gpg-sign", "-m", "one"])
        let head = try await repository.sha("HEAD")
        let missing = "0123456789abcdef0123456789abcdef01234567"

        let signatures = try await client.signatures(for: [missing, head], in: repository.root)
        #expect(signatures.keys.sorted() == [head])
        #expect(signatures[head]?.status == .unsigned)
        #expect(try await client.signatures(for: [missing], in: repository.root).isEmpty)
    }
}
