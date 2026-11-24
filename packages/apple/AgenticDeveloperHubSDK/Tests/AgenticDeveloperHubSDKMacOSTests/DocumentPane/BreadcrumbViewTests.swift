import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class BreadcrumbViewTests: XCTestCase {

    private let root = URL(fileURLWithPath: "/tmp/project")

    func testAnEmptyEditorShowsNoCrumbs() {
        let view = BreadcrumbView(rootURL: root)
        view.fileURL = nil
        XCTAssertEqual(view.crumbTitles, [])
    }

    func testCrumbsAreThePathRelativeToTheRoot() {
        let view = BreadcrumbView(rootURL: root)
        view.fileURL = URL(fileURLWithPath: "/tmp/project/Sources/App/Main.swift")
        XCTAssertEqual(view.crumbTitles, ["Sources", "App", "Main.swift"])
    }

    func testAFileOutsideTheRootFallsBackToItsOwnPath() {
        let view = BreadcrumbView(rootURL: root)
        view.fileURL = URL(fileURLWithPath: "/etc/hosts")
        XCTAssertEqual(view.crumbTitles.last, "hosts")
    }

    func testSelectingACrumbReportsItsDirectory() throws {
        let view = BreadcrumbView(rootURL: root)
        view.fileURL = URL(fileURLWithPath: "/tmp/project/Sources/App/Main.swift")
        var selected: URL?
        view.onSelect = { selected = $0 }

        view.selectCrumb(at: 1)

        XCTAssertEqual(selected?.path, "/tmp/project/Sources/App")
    }

    func testHomeRelativeCrumbsStartAtTheTilde() {
        let home = URL(fileURLWithPath: "/Users/someone")
        let view = BreadcrumbView(
            rootURL: URL(fileURLWithPath: "/Users/someone/dev/app"), style: .homeRelative, homeURL: home)
        view.fileURL = URL(fileURLWithPath: "/Users/someone/dev/app/README.md")
        XCTAssertEqual(view.crumbTitles, ["~", "dev", "app", "README.md"])
        XCTAssertEqual(view.crumbDirectories.first?.path, "/Users/someone")
        XCTAssertEqual(view.crumbDirectories.last?.path, "/Users/someone/dev/app")
    }

    func testHomeRelativeCrumbsOutsideHomeStartAtTheRoot() {
        let view = BreadcrumbView(
            rootURL: URL(fileURLWithPath: "/etc"), style: .homeRelative,
            homeURL: URL(fileURLWithPath: "/Users/someone"))
        view.fileURL = URL(fileURLWithPath: "/etc/hosts")
        XCTAssertEqual(view.crumbTitles, ["/", "etc", "hosts"])
    }

    /// A crumb's menu lists its directory, folders first and each a submenu,
    /// leaves out what the filter excludes, and reports a chosen file.
    func testACrumbsMenuListsTheDirectoryHierarchically() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("breadcrumb-menu-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("Sources"), withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        for name in ["README.md", "build.log", "Sources/Main.swift"] {
            try Data().write(to: root.appendingPathComponent(name))
        }
        let view = BreadcrumbView(rootURL: root)
        view.filter = { FileTreeFilter(rootURL: root, matcher: GitIgnoreMatcher(patterns: ["*.log"])) }
        view.fileURL = root.appendingPathComponent("README.md")
        var chosen: URL?
        view.onSelect = { chosen = $0 }

        let menu = try XCTUnwrap(view.menu(forCrumbAt: 0))
        XCTAssertEqual(menu.items.map(\.title), ["Sources", "README.md"])
        XCTAssertEqual(menu.items.last?.state, .on)

        let submenu = try XCTUnwrap(menu.items.first?.submenu)
        submenu.delegate?.menuNeedsUpdate?(submenu)
        XCTAssertEqual(submenu.items.map(\.title), ["Main.swift"])

        let file = try XCTUnwrap(submenu.items.first)
        NSApp.sendAction(try XCTUnwrap(file.action), to: file.target, from: file)
        XCTAssertEqual(chosen?.lastPathComponent, "Main.swift")
    }
}
