import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// A `ThemeStorage` that counts writes, so a test can tell "not written" from
/// "written with the same value".
@MainActor
private final class CountingThemeStorage: ThemeStorage {
    var themeWrites = 0
    var activeWrites = 0
    var customThemes: [ColorTheme] = [] { didSet { themeWrites += 1 } }
    var activeThemeID: String? { didSet { activeWrites += 1 } }
    var onExternalChange: (() -> Void)?
}

@MainActor
@Suite("ThemeStore")
struct ThemeStoreTests {

    // Each test gets a fresh store over its own in-memory storage, so nothing
    // leaks between tests and nothing touches the host's real preferences.
    let storage = InMemoryThemeStorage()
    let store: ThemeStore

    init() {
        store = ThemeStore(storage: storage)
    }

    private func sampleTheme(name: String = "Sample") -> ColorTheme {
        ColorTheme(
            name: name, appearance: .dark,
            foreground: .white, background: .black, cursor: .white, selection: .black,
            ansi: Array(repeating: .black, count: 16)
        )
    }

    // MARK: - The persistence seam

    @Test("a custom theme survives a round trip through storage")
    func customThemeRoundTrips() {
        let custom = sampleTheme(name: "Round Trip")
        store.add(custom)

        // A second store over the same storage is what "quit and relaunch" looks
        // like: nothing is cached in the store itself.
        let reloaded = ThemeStore(storage: storage)
        #expect(reloaded.allThemes.contains { $0.id == custom.id })
        #expect(reloaded.theme(withID: custom.id) == custom)
    }

    @Test("built-in themes are present without any stored data")
    func builtInsNeedNoStorage() {
        #expect(!ThemeStore(storage: InMemoryThemeStorage()).allThemes.isEmpty)
    }

    @Test("a built-in theme cannot be deleted")
    func builtInsAreUndeletable() throws {
        let builtIn = try #require(store.allThemes.first { $0.isBuiltIn })
        store.delete(id: builtIn.id)
        #expect(store.allThemes.contains { $0.id == builtIn.id })
    }

    @Test("deleting the active built-in theme leaves it active")
    func deletingActiveBuiltInKeepsIt() throws {
        let builtIn = try #require(store.allThemes.first { $0.isBuiltIn })
        storage.activeThemeID = builtIn.id
        store.delete(id: builtIn.id)
        #expect(storage.activeThemeID == builtIn.id)
    }

    // MARK: - Catalog

    @Test("starts with only the built-in themes")
    func startsWithBuiltIns() {
        #expect(store.customThemes.isEmpty)
        #expect(store.allThemes.count == BuiltInThemes.all.count)
    }

    @Test("add appends and persists a custom theme")
    func add() {
        let theme = sampleTheme()
        store.add(theme)

        #expect(store.customThemes.count == 1)
        #expect(store.allThemes.count == BuiltInThemes.all.count + 1)
        #expect(store.theme(withID: theme.id) == theme)
    }

    @Test("isBuiltIn distinguishes built-in from custom themes")
    func builtInDetection() {
        let custom = sampleTheme()
        store.add(custom)
        #expect(store.isBuiltIn(id: BuiltInThemes.defaultID))
        #expect(!store.isBuiltIn(id: custom.id))
    }

    @Test("update replaces a custom theme and ignores built-ins")
    func update() {
        var theme = sampleTheme(name: "Before")
        store.add(theme)
        theme.name = "After"
        store.update(theme)
        #expect(store.theme(withID: theme.id)?.name == "After")

        // Updating a built-in ID is a no-op (built-ins are read-only).
        var builtin = BuiltInThemes.dracula
        builtin.name = "Hacked"
        store.update(builtin)
        #expect(store.theme(withID: BuiltInThemes.dracula.id)?.name == "Dracula")
    }

    @Test("delete removes a custom theme and ignores built-ins")
    func delete() {
        let theme = sampleTheme()
        store.add(theme)
        store.delete(id: theme.id)
        #expect(store.theme(withID: theme.id) == nil)

        store.delete(id: BuiltInThemes.defaultID)
        #expect(store.theme(withID: BuiltInThemes.defaultID) != nil)
    }

    @Test("duplicate creates an editable copy with a new ID")
    func duplicate() {
        let copy = store.duplicate(BuiltInThemes.dracula)
        #expect(copy.id != BuiltInThemes.dracula.id)
        #expect(copy.isBuiltIn == false)
        #expect(copy.name == "Dracula Copy")
        #expect(copy.ansi == BuiltInThemes.dracula.ansi)
        #expect(store.customThemes.contains(copy))
    }

    @Test("importITermColors parses a file and stores it")
    func importITermColors() throws {
        var dict: [String: Any] = [
            "Foreground Color": ["Red Component": 1.0, "Green Component": 1.0, "Blue Component": 1.0],
            "Background Color": ["Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0]
        ]
        for index in 0..<16 {
            dict["Ansi \(index) Color"] = ["Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0]
        }
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Imported.itermcolors")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let imported = try store.importITermColors(contentsOf: url)
        #expect(imported.name == "Imported")
        #expect(store.theme(withID: imported.id) != nil)
    }

    @Test("addNewTheme creates an editable custom theme")
    func addNew() {
        let created = store.addNewTheme(name: "Fresh")
        #expect(created.name == "Fresh")
        #expect(created.isEditable)
        #expect(store.customThemes.contains(created))
    }

    @Test("importITermColors stores a locked, deletable import")
    func importITermMarksLocked() throws {
        var dict: [String: Any] = [
            "Foreground Color": ["Red Component": 1.0, "Green Component": 1.0, "Blue Component": 1.0],
            "Background Color": ["Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0]
        ]
        for index in 0..<16 {
            dict["Ansi \(index) Color"] = ["Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0]
        }
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Locked.itermcolors")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let imported = try store.importITermColors(contentsOf: url)
        #expect(imported.isImported)
        #expect(imported.isLocked)
        #expect(imported.isDeletable)
    }

    @Test("exportJSON → importJSON stores a locked import with a fresh id")
    func jsonRoundTripLocks() throws {
        let source = sampleTheme(name: "Shared")
        let data = try store.exportJSON(source)
        let imported = try store.importJSON(data: data)

        #expect(imported.id != source.id)          // fresh id, never collides
        #expect(imported.name == "Shared")
        #expect(imported.isImported)
        #expect(imported.isLocked)
        #expect(imported.isDeletable)
        #expect(store.theme(withID: imported.id) != nil)
    }

    @Test("importJSON refuses to let a payload masquerade as a built-in")
    func importJSONSanitizesBuiltIn() throws {
        var evil = sampleTheme(name: "Fake Builtin")
        evil.isBuiltIn = true
        let data = try store.exportJSON(evil)
        let imported = try store.importJSON(data: data)
        #expect(imported.isBuiltIn == false)
        #expect(imported.isImported)
        #expect(imported.isDeletable)
    }

    @Test("duplicating an imported theme yields a fully editable custom theme")
    func duplicateOfImportUnlocks() throws {
        let data = try store.exportJSON(sampleTheme(name: "Imp"))
        let imported = try store.importJSON(data: data)
        let copy = store.duplicate(imported)
        #expect(copy.isImported == false)
        #expect(copy.isBuiltIn == false)
        #expect(copy.isEditable)
    }

    @Test("duplicate preserves attribution")
    func duplicateKeepsAttribution() {
        var custom = sampleTheme()
        custom.attribution = "Somebody"
        store.add(custom)
        let copy = store.duplicate(custom)
        #expect(copy.attribution == "Somebody")
    }

    @Test("duplicate preserves the source theme's typography")
    func duplicatePreservesTypography() {
        var custom = sampleTheme(name: "Typed")
        custom.typography.sizeScale = 1.4
        custom.typography.styles[TextRole.body.rawValue] =
            FontStyle(family: "Menlo", size: 15, weight: .bold)
        store.add(custom)

        let copy = store.duplicate(custom)
        #expect(copy.typography == custom.typography)
        #expect(copy.typography.sizeScale == 1.4)
        #expect(copy.typography.styles[TextRole.body.rawValue]?.family == "Menlo")
    }

    // MARK: - Import validation & routing

    private func themeJSON(name: String, ansiCount: Int, foreground: String, background: String) -> Data {
        let ansi = Array(repeating: "\"#000000ff\"", count: ansiCount).joined(separator: ",")
        let json = "{\"id\":\"x\",\"name\":\"\(name)\",\"appearance\":\"dark\",\"isBuiltIn\":false,"
            + "\"foreground\":\"\(foreground)\",\"background\":\"\(background)\",\"cursor\":\"#ffffffff\","
            + "\"selection\":\"#111111ff\",\"ansi\":[\(ansi)]}"
        return Data(json.utf8)
    }

    @Test("importJSON rejects a theme without 16 ANSI colors")
    func importJSONRejectsShortPalette() {
        let data = themeJSON(name: "Broken", ansiCount: 3, foreground: "#ffffffff", background: "#000000ff")
        #expect(throws: ThemeImportError.self) { try store.importJSON(data: data) }
        #expect(store.customThemes.isEmpty)   // nothing persisted on failure
    }

    @Test("importJSON rejects a theme whose foreground equals its background")
    func importJSONRejectsInvisibleText() {
        let data = themeJSON(name: "Invisible", ansiCount: 16, foreground: "#000000ff", background: "#000000ff")
        #expect(throws: ThemeImportError.self) { try store.importJSON(data: data) }
        #expect(store.customThemes.isEmpty)
    }

    @Test("importJSON accepts a well-formed 16-color theme")
    func importJSONAcceptsValid() throws {
        let data = themeJSON(name: "Good", ansiCount: 16, foreground: "#ffffffff", background: "#000000ff")
        let imported = try store.importJSON(data: data)
        #expect(imported.name == "Good")
        #expect(imported.hasValidPalette)
        #expect(imported.isImported)
    }

    @Test("importTheme routes by content, not extension")
    func importThemeSniffsContent() throws {
        // A ColorTheme JSON saved with a .itermcolors extension still imports as JSON.
        let data = try store.exportJSON(sampleTheme(name: "Mislabeled"))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Mislabeled-\(UUID().uuidString).itermcolors")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let imported = try store.importTheme(contentsOf: url)
        #expect(imported.name == "Mislabeled")
        #expect(imported.isImported)
    }

    @Test("addNewTheme disambiguates repeated names")
    func addNewUniquifiesNames() {
        let first = store.addNewTheme(name: "New Theme")
        let second = store.addNewTheme(name: "New Theme")
        let third = store.addNewTheme(name: "New Theme")
        #expect(first.name == "New Theme")
        #expect(second.name == "New Theme 2")
        #expect(third.name == "New Theme 3")
    }

    @Test("duplicate disambiguates repeated copies")
    func duplicateUniquifiesNames() {
        let base = store.add(sampleTheme(name: "Base"))
        let first = store.duplicate(base)
        let second = store.duplicate(base)
        #expect(first.name == "Base Copy")
        #expect(second.name == "Base Copy 2")
    }

    // MARK: - Source-derived conformance vectors

    private func writeTemp(_ data: Data, named name: String = "theme.json") throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    private func removeTemp(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    private func scaledJSON(sizeScale: Int) -> Data {
        let ansi = Array(repeating: "\"#000000ff\"", count: 16).joined(separator: ",")
        let json = "{\"id\":\"x\",\"name\":\"Scaled\",\"appearance\":\"dark\",\"isBuiltIn\":false,"
            + "\"foreground\":\"#ffffffff\",\"background\":\"#000000ff\",\"cursor\":\"#ffffffff\","
            + "\"selection\":\"#111111ff\",\"ansi\":[\(ansi)],"
            + "\"typography\":{\"sizeScale\":\(sizeScale),\"styles\":{}}}"
        return Data(json.utf8)
    }

    @Test("theme-store-007 / theme-storage-010: deleting the active custom theme clears activeThemeID")
    func v007DeleteClearsActiveID() {
        let custom = store.add(sampleTheme(name: "Active"))
        storage.activeThemeID = custom.id
        store.delete(id: custom.id)
        #expect(storage.activeThemeID == nil)
        #expect(store.theme(withID: custom.id) == nil)
        #expect(!storage.customThemes.contains { $0.id == custom.id })
    }

    @Test("theme-store-009: deleting an unknown id writes nothing")
    func v009DeleteUnknownWritesNothing() {
        let counting = CountingThemeStorage()
        counting.activeThemeID = BuiltInThemes.dracula.id
        counting.themeWrites = 0
        counting.activeWrites = 0
        let counted = ThemeStore(storage: counting)

        counted.delete(id: "no-such-theme")

        #expect(counting.themeWrites == 0)
        #expect(counting.activeWrites == 0)
        #expect(counting.activeThemeID == BuiltInThemes.dracula.id)
    }

    @Test("theme-store-018: importTheme sniffs JSON past leading whitespace; an empty file takes the iTerm path")
    func v018ImportThemeWhitespaceAndEmpty() throws {
        let json = try store.exportJSON(sampleTheme(name: "Padded"))
        let padded = Data("  \t\n\r\n".utf8) + json
        let paddedURL = try writeTemp(padded)
        defer { removeTemp(paddedURL) }
        let imported = try store.importTheme(contentsOf: paddedURL)
        #expect(imported.name == "Padded")
        #expect(imported.isImported)

        let emptyURL = try writeTemp(Data(), named: "Empty.itermcolors")
        defer { removeTemp(emptyURL) }
        let before = store.customThemes
        #expect(throws: (any Error).self) { try store.importTheme(contentsOf: emptyURL) }
        #expect(store.customThemes == before)
    }

    @Test("theme-store-019: importTheme on a missing file throws the read error and stores nothing")
    func v019ImportThemeMissingFile() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)/missing.json")
        do {
            _ = try store.importTheme(contentsOf: url)
            Issue.record("importTheme should have thrown for a missing file")
        } catch {
            #expect((error as NSError).domain == NSCocoaErrorDomain)
        }
        #expect(store.customThemes.isEmpty)
    }

    @Test("theme-store-025: importJSON of non-JSON bytes throws DecodingError and stores nothing")
    func v025ImportJSONNotJSON() {
        #expect(throws: DecodingError.self) { try store.importJSON(data: Data("not json".utf8)) }
        #expect(store.customThemes.isEmpty)
    }

    @Test("theme-store-026: importJSON clamps sizeScale into 0.5...4")
    func v026ImportJSONClampsScale() throws {
        let low = try store.importJSON(data: scaledJSON(sizeScale: 0))
        let high = try store.importJSON(data: scaledJSON(sizeScale: 9))
        #expect(low.typography.sizeScale == 0.5)
        #expect(high.typography.sizeScale == 4)
        #expect(store.theme(withID: low.id)?.typography.sizeScale == 0.5)
        #expect(store.theme(withID: high.id)?.typography.sizeScale == 4)
    }

    @Test("theme-store-027: a short palette is reported before equal foreground and background")
    func v027ImportJSONCheckOrder() {
        let data = themeJSON(name: "Both", ansiCount: 3, foreground: "#000000ff", background: "#000000ff")
        do {
            _ = try store.importJSON(data: data)
            Issue.record("importJSON should have thrown")
        } catch let error as ThemeImportError {
            guard case .invalidPalette(let count) = error else {
                Issue.record("expected invalidPalette, got \(error)")
                return
            }
            #expect(count == 3)
        } catch {
            Issue.record("unexpected error \(error)")
        }
        #expect(store.customThemes.isEmpty)
    }

    @Test("theme-store-028: importJSON(contentsOf:) stores a locked import; a missing file throws")
    func v028ImportJSONURL() throws {
        let data = themeJSON(name: "FromFile", ansiCount: 16, foreground: "#ffffffff", background: "#000000ff")
        let url = try writeTemp(data)
        defer { removeTemp(url) }

        let imported = try store.importJSON(contentsOf: url)
        #expect(imported.name == "FromFile")
        #expect(imported.isLocked)
        #expect(store.theme(withID: imported.id) != nil)

        let missing = url.deletingLastPathComponent().appendingPathComponent("missing.json")
        #expect(throws: (any Error).self) { try store.importJSON(contentsOf: missing) }
        #expect(store.customThemes.count == 1)
    }

    @Test("theme-store-029: exportJSON is pretty-printed with sorted keys and decodes back equal")
    func v029ExportJSONFormat() throws {
        let theme = sampleTheme(name: "Exported")
        let data = try store.exportJSON(theme)
        let text = try #require(String(data: data, encoding: .utf8))

        #expect(text.contains("\n  \""))
        let keys = ["\"ansi\"", "\"appearance\"", "\"background\"", "\"cursor\"", "\"foreground\""]
        let positions = try keys.map { try #require(text.range(of: $0)?.lowerBound) }
        #expect(positions == positions.sorted())

        #expect(try JSONDecoder().decode(ColorTheme.self, from: data) == theme)
    }

    @Test("theme-store-030: add does not validate; a built-in's id is shadowed by the built-in on lookup")
    func v030AddUnvalidated() {
        let ordinary = store.add(sampleTheme(name: "Ordinary"))
        var clashing = sampleTheme(name: "Clashing")
        clashing.id = BuiltInThemes.dracula.id
        store.add(clashing)

        #expect(store.theme(withID: BuiltInThemes.dracula.id) == BuiltInThemes.dracula)
        #expect(store.customThemes == [ordinary, clashing])
    }

    @Test("theme-store-031: an imported iTerm name is not uniquified against existing themes")
    func v031ImportITermNameNotUniquified() throws {
        store.add(sampleTheme(name: "Imported"))
        var dict: [String: Any] = [
            "Foreground Color": ["Red Component": 1.0, "Green Component": 1.0, "Blue Component": 1.0],
            "Background Color": ["Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0]
        ]
        for index in 0..<16 {
            dict["Ansi \(index) Color"] = ["Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0]
        }
        let plist = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        let url = try writeTemp(plist, named: "Imported.itermcolors")
        defer { removeTemp(url) }

        let imported = try store.importITermColors(contentsOf: url)
        #expect(imported.name == "Imported")
        #expect(store.customThemes.map(\.name) == ["Imported", "Imported"])
    }

    @Test(
        "theme-store-032: structural guarantees (init(storage:), @MainActor, no suspension)",
        .disabled("compile-time and inspection-only vector; there is no runtime behaviour to assert")
    )
    func v032StructuralGuarantees() {}
}
