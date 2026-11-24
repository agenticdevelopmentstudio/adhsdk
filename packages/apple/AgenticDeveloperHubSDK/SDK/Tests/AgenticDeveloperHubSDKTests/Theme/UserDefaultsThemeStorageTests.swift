import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// `UserDefaultsThemeStorage` is the storage a host with no settings system of
/// its own gets for free, so what these pin is the contract `ThemeStorage`
/// states: both properties round-trip, and a change made *outside* this object
/// reports itself while this object's own writes stay silent.
@MainActor
@Suite("UserDefaultsThemeStorage", .serialized)
struct UserDefaultsThemeStorageTests {

    /// A private suite per test, so one test's themes are never another's — and
    /// never the developer's own, which `.standard` would be.
    private func makeDefaults() -> UserDefaults {
        let name = "UserDefaultsThemeStorageTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private var theme: ColorTheme {
        var custom = BuiltInThemes.solarizedDark
        custom.id = "custom.test"
        custom.name = "Test"
        return custom
    }

    @Test("a fresh domain reads as no themes and no selection")
    func emptyDefaultsReadAsEmpty() {
        let storage = UserDefaultsThemeStorage(defaults: makeDefaults())
        #expect(storage.customThemes.isEmpty)
        #expect(storage.activeThemeID == nil)
    }

    @Test("customThemes round-trips through the defaults domain")
    func customThemesRoundTrip() {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        storage.customThemes = [theme]

        // Read back through a *second* storage over the same domain: that is
        // what a relaunch is, and the only way to prove the value was written
        // rather than remembered.
        let reopened = UserDefaultsThemeStorage(defaults: defaults)
        #expect(reopened.customThemes.map(\.id) == ["custom.test"])
        #expect(reopened.customThemes.first?.name == "Test")
    }

    @Test("activeThemeID round-trips, and nil clears it")
    func activeThemeIDRoundTrips() {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        storage.activeThemeID = BuiltInThemes.githubLight.id
        #expect(UserDefaultsThemeStorage(defaults: defaults).activeThemeID == BuiltInThemes.githubLight.id)

        storage.activeThemeID = nil
        #expect(UserDefaultsThemeStorage(defaults: defaults).activeThemeID == nil)
    }

    @Test("the storage's own writes do not report as external changes")
    func ownWritesAreNotExternalChanges() async throws {
        let storage = UserDefaultsThemeStorage(defaults: makeDefaults())
        var changes = 0
        storage.onExternalChange = { changes += 1 }

        storage.activeThemeID = BuiltInThemes.githubLight.id
        storage.customThemes = [theme]
        // The notification is posted asynchronously, so give it a turn to
        // arrive before asserting it never did.
        try await Task.sleep(for: .milliseconds(50))

        #expect(changes == 0)
    }

    @Test("a write from outside the seam reports as an external change")
    func foreignWritesReportAsExternalChanges() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        var changes = 0
        storage.onExternalChange = { changes += 1 }

        // Straight at the domain, the way a settings panel bound to the raw
        // preference — or a sync from another device — would write it.
        defaults.set(BuiltInThemes.githubLight.id, forKey: UserDefaultsThemeStorage.Key.activeThemeID)
        try await Task.sleep(for: .milliseconds(50))

        #expect(changes == 1)
        #expect(storage.activeThemeID == BuiltInThemes.githubLight.id)
    }

    @Test("a corrupt custom-themes payload reads as no themes rather than trapping")
    func undecodablePayloadReadsAsEmpty() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: UserDefaultsThemeStorage.Key.customThemes)
        #expect(UserDefaultsThemeStorage(defaults: defaults).customThemes.isEmpty)
    }

    // MARK: Vectors udts-008 to udts-021

    private var customKey: String { UserDefaultsThemeStorage.Key.customThemes }
    private var activeKey: String { UserDefaultsThemeStorage.Key.activeThemeID }

    @Test("udts-008: the literal key strings")
    func udts008_keyStrings() {
        #expect(UserDefaultsThemeStorage.Key.customThemes == "theme.custom_themes")
        #expect(UserDefaultsThemeStorage.Key.activeThemeID == "theme.active_theme_id")
    }

    @Test("udts-009: an empty catalog is stored as the text []")
    func udts009_emptyCatalogWritesEmptyArray() {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        storage.customThemes = []
        #expect(defaults.data(forKey: customKey) == Data("[]".utf8))
        #expect(storage.customThemes.isEmpty)
    }

    @Test("udts-010: values present at init are not reported as changes")
    func udts010_initSnapshotIsSilent() async throws {
        let defaults = makeDefaults()
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        var changes = 0
        storage.onExternalChange = { changes += 1 }
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 0)
    }

    @Test("udts-011: a foreign write of the value already held is not a change")
    func udts011_sameValueIsSilent() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        storage.activeThemeID = BuiltInThemes.githubLight.id
        var changes = 0
        storage.onExternalChange = { changes += 1 }
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 0)
    }

    @Test("udts-012: several foreign writes in one turn report between one and four times")
    func udts012_coalescedWrites() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        var changes = 0
        storage.onExternalChange = { changes += 1 }
        defaults.set(Data("[]".utf8), forKey: customKey)
        defaults.set(Data("[ ]".utf8), forKey: customKey)
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        defaults.set(BuiltInThemes.githubDark.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes >= 1)
        #expect(changes <= 4)
    }

    @Test("udts-013: an unrelated key does not report a change")
    func udts013_unrelatedKeyIsSilent() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        var changes = 0
        storage.onExternalChange = { changes += 1 }
        defaults.set("value", forKey: "unrelated.key")
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 0)
    }

    @Test("udts-014: a write through one instance reports on the other only")
    func udts014_multipleInstances() async throws {
        let defaults = makeDefaults()
        let first = UserDefaultsThemeStorage(defaults: defaults)
        let second = UserDefaultsThemeStorage(defaults: defaults)
        var firstChanges = 0
        var secondChanges = 0
        first.onExternalChange = { firstChanges += 1 }
        second.onExternalChange = { secondChanges += 1 }
        first.activeThemeID = BuiltInThemes.githubLight.id
        try await Task.sleep(for: .milliseconds(50))
        #expect(firstChanges == 0)
        #expect(secondChanges >= 1)
    }

    @Test("udts-015: a nil callback still records the value as seen")
    func udts015_nilCallbackRecordsLastSeen() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))

        var changes = 0
        storage.onExternalChange = { changes += 1 }
        defaults.set(BuiltInThemes.githubDark.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 1)
    }

    @Test("udts-016: the defaults parameter defaults to the standard domain", .disabled(
        "Structural, by inspection: building one over .standard would observe the real domain"))
    func udts016_defaultsParameterIsStandard() {}

    @Test("udts-017: an encode failure leaves the stored catalog and last-seen record unchanged")
    func udts017_encodeFailureLeavesStorageUnchanged() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        storage.customThemes = [theme]
        let stored = defaults.data(forKey: customKey)
        #expect(stored != nil)

        var broken = BuiltInThemes.solarizedDark
        broken.id = "custom.broken"
        // The default JSONEncoder rejects a non-finite Double.
        broken.typography.sizeScale = .nan
        storage.customThemes = [broken]

        #expect(defaults.data(forKey: customKey) == stored)
        #expect(storage.customThemes.map(\.id) == ["custom.test"])

        // Rewriting the held bytes straight into the domain is silent only
        // if the last-seen record still holds them.
        var changes = 0
        storage.onExternalChange = { changes += 1 }
        defaults.set(stored, forKey: customKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 0)
    }

    @Test("udts-018: the active id is stored without validation")
    func udts018_activeIDIsNotValidated() {
        let storage = UserDefaultsThemeStorage(defaults: makeDefaults())
        storage.activeThemeID = ""
        #expect(storage.activeThemeID == "")
        storage.activeThemeID = "no.such.theme"
        #expect(storage.activeThemeID == "no.such.theme")
    }

    @Test("udts-019: a released storage stops observing")
    func udts019_deinitRemovesObserver() async throws {
        let defaults = makeDefaults()
        var changes = 0
        var storage: UserDefaultsThemeStorage? = UserDefaultsThemeStorage(defaults: defaults)
        storage?.onExternalChange = { changes += 1 }
        storage = nil
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(storage == nil)
        #expect(changes == 0)
    }

    @Test("udts-020: the external-change callback runs on the main thread")
    func udts020_callbackRunsOnMainActor() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        var ranOnMain: Bool?
        storage.onExternalChange = { ranOnMain = Thread.isMainThread }
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(ranOnMain == true)
    }

    @Test("udts-021: one error log per failure", .disabled(
        "A unit test cannot read os.Logger output without a log-store entitlement"))
    func udts021_failureLogging() {}

    // MARK: Theme-storage conformance vectors

    @Test("theme-storage-011: InMemoryThemeStorage never invokes the hook")
    func themeStorage011_inMemoryNeverInvokesHook() async throws {
        let memory = InMemoryThemeStorage()
        var changes = 0
        memory.onExternalChange = { changes += 1 }
        memory.activeThemeID = BuiltInThemes.githubLight.id
        memory.customThemes = [theme]
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 0)
    }

    @Test("theme-storage-012: a theme with a non-finite terminal fontSize leaves the stored catalog unchanged")
    func themeStorage012_unencodableTerminalFontSize() {
        let storage = UserDefaultsThemeStorage(defaults: makeDefaults())
        storage.customThemes = [theme]

        var broken = theme
        broken.id = "custom.broken"
        broken.terminal = ThemeTerminalOptions(fontSize: .nan)
        storage.customThemes = [theme, broken]

        #expect(storage.customThemes.map(\.id) == ["custom.test"])
    }

    @Test("theme-storage-013 (also udts-011): a foreign write of the value already held is not a change")
    func themeStorage013_sameValueWriteIsCoalesced() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        storage.activeThemeID = BuiltInThemes.githubLight.id
        try await Task.sleep(for: .milliseconds(50))

        var changes = 0
        storage.onExternalChange = { changes += 1 }
        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))
        #expect(changes == 0)
    }

    @Test("theme-storage-014: back-to-back foreign writes report at most twice and read the last value")
    func themeStorage014_backToBackForeignWrites() async throws {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        var changes = 0
        storage.onExternalChange = { changes += 1 }

        defaults.set(BuiltInThemes.githubLight.id, forKey: activeKey)
        defaults.set(BuiltInThemes.dracula.id, forKey: activeKey)
        try await Task.sleep(for: .milliseconds(50))

        #expect(changes >= 1 && changes <= 2)
        #expect(storage.activeThemeID == BuiltInThemes.dracula.id)
    }

    @Test("theme-storage-015: the injected suite receives the write and .standard does not")
    func themeStorage015_injectableDomain() {
        let defaults = makeDefaults()
        let storage = UserDefaultsThemeStorage(defaults: defaults)
        let marker = "marker-\(UUID().uuidString)"
        storage.activeThemeID = marker

        #expect(defaults.string(forKey: "theme.active_theme_id") == marker)
        #expect(UserDefaults.standard.string(forKey: "theme.active_theme_id") != marker)
    }

    @Test("theme-storage-016: custom themes read back in the order written")
    func themeStorage016_customThemesOrder() {
        let defaults = makeDefaults()
        var ordered: [ColorTheme] = []
        for identifier in ["a", "b", "c"] {
            var item = theme
            item.id = identifier
            ordered.append(item)
        }
        UserDefaultsThemeStorage(defaults: defaults).customThemes = ordered
        #expect(UserDefaultsThemeStorage(defaults: defaults).customThemes.map(\.id) == ["a", "b", "c"])
    }
}
