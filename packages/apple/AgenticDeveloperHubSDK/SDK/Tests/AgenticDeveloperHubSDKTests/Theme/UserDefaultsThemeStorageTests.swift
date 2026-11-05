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

        #expect(changes >= 1)
        #expect(storage.activeThemeID == BuiltInThemes.githubLight.id)
    }

    @Test("a corrupt custom-themes payload reads as no themes rather than trapping")
    func undecodablePayloadReadsAsEmpty() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: UserDefaultsThemeStorage.Key.customThemes)
        #expect(UserDefaultsThemeStorage(defaults: defaults).customThemes.isEmpty)
    }
}
