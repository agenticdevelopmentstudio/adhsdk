import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("JSON file privacy word store") struct JSONFilePrivacyWordStoreTests {
    private func scratchFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PrivacyWordStorageTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("nested/words.json")
    }

    @Test("F1: a missing file is no words")
    func testF1_missingFile() throws {
        #expect(try JSONFilePrivacyWordStore(fileURL: scratchFile()).load() == [])
    }

    @Test("F2: save then load round-trips every field, creating the folder")
    func testF2_roundTrip() throws {
        let url = scratchFile()
        let store = JSONFilePrivacyWordStore(fileURL: url)
        let words = [
            PrivacyWord(alias: "Sunflower", real: "Zorblax"),
            PrivacyWord(alias: "Tulip", real: "Quuxcorp", isEnabled: false, sites: ["example.com/*"])
        ]
        try store.save(words)
        #expect(try store.load() == words)
        #expect(try JSONFilePrivacyWordStore(fileURL: url).load() == words)
    }

    @Test("F3: a hand-written file in the keychain's encoding reads, bare pairs as enabled words on *")
    func testF3_handWritten() throws {
        let url = scratchFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let json = #"[{"alias":"Sunflower","real":"Zorblax"},"#
            + #"{"alias":"Tulip","real":"Q","enabled":false,"sites":["a.com"]}]"#
        try Data(json.utf8).write(to: url)
        let words = try JSONFilePrivacyWordStore(fileURL: url).load()
        #expect(words == [
            PrivacyWord(alias: "Sunflower", real: "Zorblax"),
            PrivacyWord(alias: "Tulip", real: "Q", isEnabled: false, sites: ["a.com"])
        ])
    }

    @Test("F4: a file that is not privacy words JSON throws unreadable instead of reading as empty")
    func testF4_badJSON() throws {
        let url = scratchFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: url)
        #expect(throws: PrivacyWordStore.StoreError.unreadable) { try JSONFilePrivacyWordStore(fileURL: url).load() }
    }

    @Test("F5: the change identity names the file, so two files never hear each other")
    func testF5_identity() {
        let one = JSONFilePrivacyWordStore(fileURL: URL(fileURLWithPath: "/tmp/a/../one.json"))
        let same = JSONFilePrivacyWordStore(fileURL: URL(fileURLWithPath: "/tmp/one.json"))
        let other = JSONFilePrivacyWordStore(fileURL: URL(fileURLWithPath: "/tmp/two.json"))
        #expect(one.changeIdentity == same.changeIdentity)
        #expect(one.changeIdentity != other.changeIdentity)
        #expect(PrivacyWordsVault.changedNotification(for: one).rawValue == "file:/tmp/one.json.changed")
    }

    @Test("F6: an empty save leaves an empty list, not a missing file")
    func testF6_emptySave() throws {
        let url = scratchFile()
        let store = JSONFilePrivacyWordStore(fileURL: url)
        try store.save([])
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try store.load() == [])
    }
}

@Suite("In-memory privacy word store") struct InMemoryPrivacyWordStoreTests {
    @Test("M1: holds what is saved and counts saves")
    func testM1_saves() throws {
        let store = InMemoryPrivacyWordStore()
        try store.save([PrivacyWord(alias: "a", real: "b")])
        #expect(try store.load() == [PrivacyWord(alias: "a", real: "b")])
        #expect(store.saveCount == 1)
    }

    @Test("M2: a guarded store needs a context until it is saved again")
    func testM2_guarded() throws {
        let store = InMemoryPrivacyWordStore(words: [PrivacyWord(alias: "a", real: "b")], requiresAuthentication: true)
        #expect(throws: PrivacyWordStore.StoreError.needsAuthentication) { try store.load() }
        #expect(try store.load(context: .init()) == [PrivacyWord(alias: "a", real: "b")])
        try store.save(store.load(context: .init()))
        #expect(try store.load() == [PrivacyWord(alias: "a", real: "b")])
    }

    @Test("M3: two stores have different identities unless given one")
    func testM3_identity() {
        #expect(InMemoryPrivacyWordStore().changeIdentity != InMemoryPrivacyWordStore().changeIdentity)
        #expect(InMemoryPrivacyWordStore(changeIdentity: "x").changeIdentity == "x")
    }
}

@MainActor
@Suite("Privacy testing words") struct PrivacyTestingWordsTests {
    private let real = InMemoryPrivacyWordStore(words: [PrivacyWord(alias: "RealAlias", real: "RealSecret")])

    private func settings() -> SettingsStore {
        SettingsStore(with: InMemorySettingsStorageProvider(),
                      secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    private func testingFile(_ words: [PrivacyWord]) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrivacyTestingWordsTests-\(UUID().uuidString).json")
        try JSONFilePrivacyWordStore(fileURL: url).save(words)
        return url
    }

    private let fake = PrivacyWord(alias: "Sunflower", real: "Zorblax")

    @Test("T1: off by default — the vault stays on the real words")
    func testT1_default() throws {
        let vault = PrivacyWordsVault(store: real, authenticator: ScriptedOwnerAuthenticator())
        let subject = PrivacyTestingWords(vault: vault, settings: settings())
        subject.start()
        #expect(!subject.isUsingTestingWords)
        try vault.load()
        #expect(vault.words == real.words)
    }

    @Test("T2: on with a path at start — the vault reads the file and never the real words")
    func testT2_onAtStart() throws {
        let store = settings()
        store.set(true, for: UserSettings.privacyTestingWordsEnabled)
        store.set(try testingFile([fake]).path, for: UserSettings.privacyTestingWordsPath)
        let realSpy = FaultyPrivacyWordStore(real)
        let vault = PrivacyWordsVault(store: realSpy, authenticator: ScriptedOwnerAuthenticator())
        let subject = PrivacyTestingWords(vault: vault, settings: store)
        subject.start()
        try vault.load()
        #expect(subject.isUsingTestingWords)
        #expect(vault.words == [fake])
        #expect(realSpy.loadCount == 0)
        #expect(vault.authenticator is UnattendedOwnerAuthenticator)
    }

    @Test("T3: on without a path stays on the real words")
    func testT3_noPath() {
        let store = settings()
        store.set(true, for: UserSettings.privacyTestingWordsEnabled)
        store.set("   ", for: UserSettings.privacyTestingWordsPath)
        let vault = PrivacyWordsVault(store: real, authenticator: ScriptedOwnerAuthenticator())
        let subject = PrivacyTestingWords(vault: vault, settings: store)
        subject.start()
        #expect(!subject.isUsingTestingWords)
        #expect(PrivacyTestingWords.fileURL(in: store) == nil)
    }

    @Test("T4: turning it on and off while running swaps a loaded vault live")
    func testT4_live() async throws {
        let store = settings()
        store.set(try testingFile([fake]).path, for: UserSettings.privacyTestingWordsPath)
        let owner = ScriptedOwnerAuthenticator()
        let vault = PrivacyWordsVault(store: real, authenticator: owner)
        let subject = PrivacyTestingWords(vault: vault, settings: store)
        subject.start()
        try vault.load()
        #expect(vault.words == real.words)

        store.set(true, for: UserSettings.privacyTestingWordsEnabled)
        await settleNotifications(100_000_000)
        #expect(vault.words == [fake])

        store.set(false, for: UserSettings.privacyTestingWordsEnabled)
        await settleNotifications(100_000_000)
        #expect(vault.words == real.words)
        #expect(vault.authenticator as? ScriptedOwnerAuthenticator === owner)
    }

    @Test("T5: authenticating on testing words never prompts, and saving writes the file")
    func testT5_noPromptAndSave() async throws {
        let store = settings()
        let url = try testingFile([fake])
        store.set(true, for: UserSettings.privacyTestingWordsEnabled)
        store.set(url.path, for: UserSettings.privacyTestingWordsPath)
        let owner = ScriptedOwnerAuthenticator(.fail)
        let vault = PrivacyWordsVault(store: real, authenticator: owner)
        PrivacyTestingWords(vault: vault, settings: store).start()

        let grant = try await vault.authenticate(reason: "edit the privacy words")
        #expect(owner.promptCount == 0)
        let added = PrivacyWord(alias: "Tulip", real: "Quuxcorp", sites: ["example.com/*"])
        try vault.save([fake, added], with: grant)
        #expect(try JSONFilePrivacyWordStore(fileURL: url).load() == [fake, added])
        #expect(real.words == [PrivacyWord(alias: "RealAlias", real: "RealSecret")])
    }

    @Test("T6: a tilde in the path is expanded")
    func testT6_tilde() {
        let store = settings()
        store.set(true, for: UserSettings.privacyTestingWordsEnabled)
        store.set("~/words.json", for: UserSettings.privacyTestingWordsPath)
        #expect(PrivacyTestingWords.fileURL(in: store)?.path
                == (NSHomeDirectory() as NSString).appendingPathComponent("words.json"))
    }

    @Test("T7: a grant from the testing words' no-prompt answer does not show the real words")
    func testT7_turningOffRevokes() async throws {
        let store = settings()
        store.set(true, for: UserSettings.privacyTestingWordsEnabled)
        store.set(try testingFile([fake]).path, for: UserSettings.privacyTestingWordsPath)
        let owner = ScriptedOwnerAuthenticator(.fail)
        let vault = PrivacyWordsVault(store: real, authenticator: owner)
        PrivacyTestingWords(vault: vault, settings: store).start()
        let grant = try await vault.authenticate(reason: "show your secrets")
        #expect(try vault.words(with: grant) == [fake])

        store.set(false, for: UserSettings.privacyTestingWordsEnabled)
        await settleNotifications(100_000_000)
        #expect(throws: PrivacyWordsGrant.Revoked.self) { try vault.words(with: grant) }
        await #expect(throws: PrivacyWordStore.StoreError.self) {
            try await vault.authenticate(reason: "show your secrets")
        }
        #expect(owner.promptCount == 1)
    }
}
