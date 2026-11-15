import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// The options a `createWebviewPanel` call carries, and the two rules that are
/// easy to get subtly wrong: forms default to whatever scripts did, and an
/// extension that declared *no* resource roots is not the same as one that
/// declared none at all.
@Suite
struct WebviewPanelOptionsTests {

    private let extensionDirectory =
        URL(fileURLWithPath: "/Users/someone/.agenticextensions/vendor.preview")
    private let workspace = URL(fileURLWithPath: "/Users/someone/Development/whippet")
    private let secondWorkspace = URL(fileURLWithPath: "/Users/someone/Development/other")

    @Test("wpo-001: scripts are off unless the panel asked for them")
    func scriptsAreOffUnlessAskedFor() {
        #expect(
            WebviewPanelOptions(enableScripts: nil, enableForms: nil, localResourceRoots: nil)
                .enableScripts == false)
        #expect(
            WebviewPanelOptions(enableScripts: true, enableForms: nil, localResourceRoots: nil)
                .enableScripts)
    }

    /// `vscode.d.ts`: "Defaults to true if scripts are enabled. Otherwise
    /// defaults to false." A scripted page whose forms are silently refused
    /// fails invisibly — the click does nothing and only a content-policy
    /// console line says why.
    @Test("wpo-002: forms default to whatever scripts did")
    func formsFollowScripts() {
        #expect(
            WebviewPanelOptions(enableScripts: true, enableForms: nil, localResourceRoots: nil)
                .enableForms)
        #expect(
            WebviewPanelOptions(enableScripts: false, enableForms: nil, localResourceRoots: nil)
                .enableForms == false)
    }

    @Test("wpo-003: an explicit forms option beats the default in both directions")
    func formsCanBeSetAgainstScripts() {
        #expect(
            WebviewPanelOptions(enableScripts: false, enableForms: true, localResourceRoots: nil)
                .enableForms)
        #expect(
            WebviewPanelOptions(enableScripts: true, enableForms: false, localResourceRoots: nil)
                .enableForms == false)
    }

    /// Upstream's default, and the smallest one that gets a preview on screen:
    /// an extension renders its own stylesheet *and* the user's images.
    @Test("wpo-004: a panel that declared no roots gets its extension and the workspace")
    func undeclaredRootsAreTheExtensionAndTheWorkspace() {
        let options = WebviewPanelOptions(
            enableScripts: nil, enableForms: nil, localResourceRoots: nil)

        let roots = options.resourceRoots(
            extensionDirectory: extensionDirectory, workspaceRoots: [workspace, secondWorkspace])

        #expect(roots.count == 3)
        #expect(roots.first?.path == extensionDirectory.path)
        #expect(roots.map(\.path).contains(workspace.path))
    }

    @Test("wpo-005: declared roots replace the default rather than adding to it")
    func declaredRootsAreTheOnlyRoots() {
        let options = WebviewPanelOptions(
            enableScripts: nil, enableForms: nil, localResourceRoots: [workspace])

        let roots = options.resourceRoots(
            extensionDirectory: extensionDirectory, workspaceRoots: [secondWorkspace])

        #expect(roots.map(\.path) == [workspace.path])
    }

    /// The distinction the `nil` in `declaredLocalResourceRoots` exists for:
    /// an extension that deliberately renounced file access must not be handed
    /// the whole workspace by a default meant for one that never mentioned it.
    @Test("wpo-006: an empty declaration means no file access at all")
    func anEmptyDeclarationIsNoAccess() {
        let options = WebviewPanelOptions(
            enableScripts: nil, enableForms: nil, localResourceRoots: [])

        let roots = options.resourceRoots(
            extensionDirectory: extensionDirectory, workspaceRoots: [workspace])

        #expect(roots.isEmpty)
    }

    @Test("wpo-007: a repeated root is listed once, in the place it was first seen")
    func rootsAreDeduplicated() {
        let options = WebviewPanelOptions(
            enableScripts: nil, enableForms: nil, localResourceRoots: nil)

        let roots = options.resourceRoots(
            extensionDirectory: extensionDirectory,
            workspaceRoots: [workspace, workspace, extensionDirectory])

        #expect(roots.count == 2)
        #expect(roots.first?.path == extensionDirectory.path)
    }

    /// Deduplicated by the same canonical form the containment check downstream
    /// uses, so two entries this left in place could never be read as one root
    /// there.
    @Test("wpo-008: four spellings of one directory are one root")
    func spellingsOfOneDirectoryAreOneRoot() {
        let options = WebviewPanelOptions(
            enableScripts: nil, enableForms: nil,
            localResourceRoots: [
                workspace,
                URL(fileURLWithPath: workspace.path + "/"),
                URL(fileURLWithPath: workspace.path + "/./"),
                workspace.appendingPathComponent("Sources").appendingPathComponent("..")
            ])

        let roots = options.resourceRoots(extensionDirectory: extensionDirectory, workspaceRoots: [])

        #expect(roots.count == 1)
    }

    @Test("wpo-009: the policy shuts the same three doors either way", arguments: [true, false])
    func theContentPolicyAlwaysShutsTheSameThreeDoors(_ allowingForms: Bool) {
        let policy = WebviewPanelOptions.contentSecurityPolicy(allowingForms: allowingForms)

        #expect(policy.contains("object-src 'none'"))
        #expect(policy.contains("base-uri 'none'"))
        #expect(policy.contains("frame-ancestors 'none'"))
    }

    /// Lifted by *omission*, not by widening to `'self'`: a directive this
    /// policy names is one the page's own CSP can no longer loosen, and an
    /// extension that turned forms on is entitled to say where they go.
    @Test("wpo-010: form-action follows the forms option")
    func formActionFollowsTheFormsOption() {
        #expect(
            WebviewPanelOptions.contentSecurityPolicy(allowingForms: false)
                .contains("form-action 'none'"))
        #expect(
            WebviewPanelOptions.contentSecurityPolicy(allowingForms: true)
                .contains("form-action") == false)
    }

    @Test("wpo-011: a panel's own policy reflects the forms it defaulted to")
    func thePolicyIsWhatThePanelAskedFor() {
        let options = WebviewPanelOptions(
            enableScripts: true, enableForms: nil, localResourceRoots: nil)

        #expect(options.contentSecurityPolicy.contains("form-action") == false)
    }

    @Test("wpo-012: the policy string has a fixed directive order")
    func policyDirectiveOrder() {
        #expect(
            WebviewPanelOptions.contentSecurityPolicy(allowingForms: false)
                == "object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'")
    }

    @Test("wpo-013: equality compares all three fields")
    func valueSemantics() {
        let base = WebviewPanelOptions(
            enableScripts: true, enableForms: true, declaredLocalResourceRoots: [workspace])
        let same = WebviewPanelOptions(
            enableScripts: true, enableForms: true, declaredLocalResourceRoots: [workspace])
        #expect(base == same)
        #expect(base != WebviewPanelOptions(
            enableScripts: false, enableForms: true, declaredLocalResourceRoots: [workspace]))
        #expect(base != WebviewPanelOptions(
            enableScripts: true, enableForms: false, declaredLocalResourceRoots: [workspace]))
        #expect(base != WebviewPanelOptions(
            enableScripts: true, enableForms: true, declaredLocalResourceRoots: [secondWorkspace]))
    }

    @Test("wpo-014: an empty object decodes to the defaults")
    func decodeEmptyObject() throws {
        let options = try JSONDecoder().decode(WebviewPanelOptions.self, from: Data("{}".utf8))
        #expect(options.enableScripts == false)
        #expect(options.enableForms == false)
        #expect(options.declaredLocalResourceRoots == nil)
    }

    @Test("wpo-015: roots decode from plain path strings")
    func decodeRootsAsPaths() throws {
        let json = #"{"enableScripts": true, "enableForms": true, "localResourceRoots": ["/a/b", "/c/d"]}"#
        let options = try JSONDecoder().decode(WebviewPanelOptions.self, from: Data(json.utf8))
        #expect(options.declaredLocalResourceRoots == [
            URL(fileURLWithPath: "/a/b"), URL(fileURLWithPath: "/c/d")
        ])
    }

    @Test("wpo-016: roots encode as plain path strings and round-trip")
    func encodeRootsAsPaths() throws {
        let options = WebviewPanelOptions(
            enableScripts: true, enableForms: false,
            declaredLocalResourceRoots: [URL(fileURLWithPath: "/a/b")])
        let data = try JSONEncoder().encode(options)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["localResourceRoots"] as? [String] == ["/a/b"])
        #expect(try JSONDecoder().decode(WebviewPanelOptions.self, from: data) == options)
    }

    @Test("wpo-017: absent roots leave the key out")
    func encodeAbsentRootsOmitsKey() throws {
        let options = WebviewPanelOptions(
            enableScripts: true, enableForms: true, declaredLocalResourceRoots: nil)
        let data = try JSONEncoder().encode(options)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["localResourceRoots"] == nil)
        #expect(Set(object.keys) == ["enableScripts", "enableForms"])
    }

    @Test("wpo-018: the resolved initializer runs no derivation")
    func resolvedInitializerNoDerivation() {
        let options = WebviewPanelOptions(
            enableScripts: false, enableForms: true, declaredLocalResourceRoots: nil)
        #expect(options.enableForms)
        #expect(options.enableScripts == false)
    }

    @Test("wpo-019: only the three declared fields are exposed")
    func fieldReduction() throws {
        let options = WebviewPanelOptions(
            enableScripts: true, enableForms: true, declaredLocalResourceRoots: [workspace])
        let labels = Mirror(reflecting: options).children.compactMap(\.label)
        #expect(Set(labels) == ["enableScripts", "enableForms", "declaredLocalResourceRoots"])
        let data = try JSONEncoder().encode(options)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["enableScripts", "enableForms", "localResourceRoots"])
    }

    @Test("wpo-020: concurrent callers each get the result their inputs imply")
    func concurrentAccess() async {
        let options = WebviewPanelOptions(
            enableScripts: true, enableForms: false, declaredLocalResourceRoots: nil)
        let directory = extensionDirectory
        let roots = [workspace]
        let results = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    let resolved = options.resourceRoots(extensionDirectory: directory, workspaceRoots: roots)
                    return resolved.count == 2
                        && options.contentSecurityPolicy.contains("form-action 'none'")
                }
            }
            return await group.reduce(into: [Bool]()) { $0.append($1) }
        }
        #expect(results.count == 50)
        #expect(results.allSatisfy { $0 })
    }

    @Test("wpo-021: resolving roots does not change the directory")
    func resolvingRootsDoesNotWrite() throws {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        try Data("x".utf8).write(to: scratch.appendingPathComponent("file.txt"))

        let before = try FileManager.default.contentsOfDirectory(atPath: scratch.path).sorted()
        let options = WebviewPanelOptions(
            enableScripts: nil, enableForms: nil, localResourceRoots: nil)
        _ = options.resourceRoots(extensionDirectory: scratch, workspaceRoots: [scratch])
        let after = try FileManager.default.contentsOfDirectory(atPath: scratch.path).sorted()

        #expect(before == after)
    }

    @Test("wpo-022: absent and empty roots are stored as written")
    func rootsDeclarationPreserved() {
        let absent = WebviewPanelOptions(enableScripts: nil, enableForms: nil, localResourceRoots: nil)
        let empty = WebviewPanelOptions(enableScripts: nil, enableForms: nil, localResourceRoots: [])
        #expect(absent.declaredLocalResourceRoots == nil)
        #expect(empty.declaredLocalResourceRoots == [])
    }
}
